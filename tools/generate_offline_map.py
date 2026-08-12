#!/usr/bin/env python3
"""Generate the bundled Córdoba MapLibre/PMTiles asset package.

The script uses only Python's standard library. It downloads the official
Stadia styles, vector tiles, sprites, and glyphs, creates an MBTiles database,
converts it to PMTiles with the official go-pmtiles CLI, and atomically replaces
assets/map after every output has been validated.
It also produces assets/offline_map.zip, the optional Flutter asset consumed at
runtime. Keeping the package directly under assets/ lets Flutter compile when
the generated map is absent without placeholder directories.
"""

from __future__ import annotations

import argparse
import getpass
import hashlib
import json
import math
import os
import platform
import re
import shutil
import sqlite3
import subprocess
import sys
import tarfile
import tempfile
import time
import zipfile
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Sequence
from urllib.error import HTTPError, URLError
from urllib.parse import quote, urljoin, urlsplit, urlunsplit
from urllib.request import Request, urlopen


DEFAULT_HOST = "https://tiles-eu.stadiamaps.com"
DEFAULT_BOUNDS = (-4.942937979624105, 37.828534654889125,
                  -4.647998576490011, 38.0287198393342)
DEFAULT_CENTER = (-4.7871324, 37.8916417, 13)
DEFAULT_GLYPH_RANGES = ("0-255", "256-511")
PMTILES_VERSION = "1.31.2"
USER_AGENT = "aucorsa-offline-map-generator/1.0"
GENERATOR_ID = "tools/generate_offline_map.py"
ATTRIBUTION = "© Stadia Maps © OpenMapTiles © OpenStreetMap contributors"


class GenerationError(RuntimeError):
    """Raised when remote or generated map data is incomplete."""


@dataclass(frozen=True, order=True)
class Tile:
    zoom: int
    x: int
    y: int


@dataclass(frozen=True)
class StyleSpec:
    output_name: str
    remote_name: str
    sprite_directory: str


STYLES = (
    StyleSpec("light", "alidade_smooth", "alidade-smooth"),
    StyleSpec("dark", "alidade_smooth_dark", "alidade-smooth-dark"),
)


class StadiaClient:
    def __init__(self, api_key: str, timeout: float) -> None:
        self.api_key = api_key
        self.timeout = timeout

    def bytes(self, url: str, accept: str = "*/*") -> bytes:
        hostname = (urlsplit(url).hostname or "").lower()
        if hostname != "stadiamaps.com" and not hostname.endswith(".stadiamaps.com"):
            raise GenerationError("Refusing to send the Stadia API key to another host")
        request = Request(
            url,
            headers={
                "Accept": accept,
                "User-Agent": USER_AGENT,
            },
        )
        # urllib copies normal headers across redirects. Marking authentication
        # as unredirected prevents a future CDN redirect from receiving the key.
        request.add_unredirected_header(
            "Authorization",
            f"Stadia-Auth {self.api_key}",
        )

        for attempt in range(4):
            try:
                with urlopen(request, timeout=self.timeout) as response:
                    return response.read()
            except HTTPError as error:
                retryable = error.code in {429, 500, 502, 503, 504}
                if not retryable or attempt == 3:
                    raise GenerationError(
                        f"Stadia request failed with HTTP {error.code}"
                    ) from error
            except (TimeoutError, URLError) as error:
                if attempt == 3:
                    raise GenerationError(f"Stadia request failed: {error}") from error

            time.sleep(2**attempt)

        raise AssertionError("unreachable")

    def json(self, url: str) -> dict[str, Any]:
        raw = self.bytes(url, "application/json")
        try:
            value = json.loads(raw)
        except json.JSONDecodeError as error:
            raise GenerationError("Stadia returned invalid JSON") from error
        if not isinstance(value, dict):
            raise GenerationError("Stadia returned a non-object JSON document")
        return value


def parse_args(argv: Sequence[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--api-key",
        default=os.environ.get("STADIA_MAPS_API_KEY"),
        help=(
            "Stadia API key. Prefer STADIA_MAPS_API_KEY or the hidden prompt "
            "so the key does not appear in the process list"
        ),
    )
    parser.add_argument(
        "--host",
        default=DEFAULT_HOST,
        help=f"Stadia tile host (default: {DEFAULT_HOST})",
    )
    parser.add_argument(
        "--bounds",
        type=parse_bounds,
        default=DEFAULT_BOUNDS,
        metavar="WEST,SOUTH,EAST,NORTH",
        help="logical service bounds used to select tiles",
    )
    parser.add_argument("--min-zoom", type=int, default=11)
    parser.add_argument("--max-zoom", type=int, default=14)
    parser.add_argument(
        "--ring",
        type=int,
        default=1,
        help="extra tile ring around the bounds at every zoom (default: 1)",
    )
    parser.add_argument(
        "--center",
        type=parse_center,
        default=DEFAULT_CENTER,
        metavar="LONGITUDE,LATITUDE,ZOOM",
    )
    parser.add_argument(
        "--glyph-ranges",
        type=parse_glyph_ranges,
        default=DEFAULT_GLYPH_RANGES,
        metavar="0-255,256-511",
    )
    parser.add_argument("--workers", type=int, default=8)
    parser.add_argument("--timeout", type=float, default=30)
    parser.add_argument(
        "--max-tiles",
        type=int,
        default=5000,
        help="safety limit for the number of requested tiles (default: 5000)",
    )
    parser.add_argument(
        "--pmtiles-bin",
        type=Path,
        help="existing pmtiles CLI; otherwise the pinned official binary is cached",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        help="output directory (default: <repository>/assets/map)",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="replace an output directory not created by this generator",
    )
    return parser.parse_args(argv)


def parse_bounds(value: str) -> tuple[float, float, float, float]:
    values = _parse_float_tuple(value, 4, "bounds")
    west, south, east, north = values
    if not (-180 <= west < east <= 180 and -85.051129 <= south < north <= 85.051129):
        raise argparse.ArgumentTypeError("bounds are invalid or outside Web Mercator")
    return west, south, east, north


def parse_center(value: str) -> tuple[float, float, int]:
    values = _parse_float_tuple(value, 3, "center")
    longitude, latitude, zoom_value = values
    zoom = int(zoom_value)
    if zoom != zoom_value or not (-180 <= longitude <= 180 and -90 <= latitude <= 90):
        raise argparse.ArgumentTypeError("center must be LONGITUDE,LATITUDE,INTEGER_ZOOM")
    return longitude, latitude, zoom


def parse_glyph_ranges(value: str) -> tuple[str, ...]:
    ranges = tuple(item.strip() for item in value.split(",") if item.strip())
    if not ranges:
        raise argparse.ArgumentTypeError("at least one glyph range is required")
    for glyph_range in ranges:
        match = re.fullmatch(r"(\d+)-(\d+)", glyph_range)
        if match is None:
            raise argparse.ArgumentTypeError(f"invalid glyph range: {glyph_range}")
        start, end = map(int, match.groups())
        if start % 256 != 0 or end != start + 255:
            raise argparse.ArgumentTypeError(
                f"glyph range must be a 256-code-point block: {glyph_range}"
            )
    return ranges


def _parse_float_tuple(value: str, count: int, name: str) -> tuple[float, ...]:
    try:
        values = tuple(float(item.strip()) for item in value.split(","))
    except ValueError as error:
        raise argparse.ArgumentTypeError(f"{name} must contain numbers") from error
    if len(values) != count:
        raise argparse.ArgumentTypeError(f"{name} requires {count} comma-separated values")
    return values


def resolve_api_key(value: str | None) -> str:
    api_key = value or getpass.getpass("Stadia Maps API key: ")
    api_key = api_key.strip()
    if not api_key:
        raise GenerationError("A Stadia Maps API key is required")
    return api_key


def resolve_tiles(
    bounds: tuple[float, float, float, float],
    min_zoom: int,
    max_zoom: int,
    ring: int,
) -> list[Tile]:
    if not 0 <= min_zoom <= max_zoom <= 24:
        raise GenerationError("zoom levels must satisfy 0 <= min <= max <= 24")
    if ring < 0:
        raise GenerationError("ring must be non-negative")

    west, south, east, north = bounds
    result: list[Tile] = []
    for zoom in range(min_zoom, max_zoom + 1):
        dimension = 1 << zoom
        min_x = max(0, longitude_to_tile_x(west, zoom) - ring)
        max_x = min(dimension - 1, longitude_to_tile_x(east, zoom) + ring)
        min_y = max(0, latitude_to_tile_y(north, zoom) - ring)
        max_y = min(dimension - 1, latitude_to_tile_y(south, zoom) + ring)
        result.extend(
            Tile(zoom, x, y)
            for x in range(min_x, max_x + 1)
            for y in range(min_y, max_y + 1)
        )
    return result


def longitude_to_tile_x(longitude: float, zoom: int) -> int:
    dimension = 1 << zoom
    return min(dimension - 1, max(0, math.floor((longitude + 180) / 360 * dimension)))


def latitude_to_tile_y(latitude: float, zoom: int) -> int:
    latitude_radians = math.radians(latitude)
    dimension = 1 << zoom
    value = (1 - math.asinh(math.tan(latitude_radians)) / math.pi) / 2
    return min(dimension - 1, max(0, math.floor(value * dimension)))


def tile_x_to_longitude(x: int, zoom: int) -> float:
    return x / (1 << zoom) * 360 - 180


def tile_y_to_latitude(y: int, zoom: int) -> float:
    mercator = math.pi - 2 * math.pi * y / (1 << zoom)
    return math.degrees(math.atan(math.sinh(mercator)))


def archive_bounds(tiles: Sequence[Tile]) -> tuple[float, float, float, float]:
    return (
        min(tile_x_to_longitude(tile.x, tile.zoom) for tile in tiles),
        min(tile_y_to_latitude(tile.y + 1, tile.zoom) for tile in tiles),
        max(tile_x_to_longitude(tile.x + 1, tile.zoom) for tile in tiles),
        max(tile_y_to_latitude(tile.y, tile.zoom) for tile in tiles),
    )


def download_style_resources(
    client: StadiaClient,
    host: str,
    stage: Path,
    glyph_ranges: Sequence[str],
    api_key: str,
) -> list[str]:
    styles: list[dict[str, Any]] = []
    install_files: list[str] = []

    for spec in STYLES:
        raw = client.bytes(
            f"{host}/styles/{spec.remote_name}.json",
            "application/json",
        )
        if api_key.encode() in raw:
            raise GenerationError("Stadia returned a style containing the API key")
        try:
            style = json.loads(raw)
        except json.JSONDecodeError as error:
            raise GenerationError(f"{spec.remote_name} style is invalid JSON") from error
        if not isinstance(style, dict) or style.get("version") != 8:
            raise GenerationError(f"{spec.remote_name} is not a MapLibre v8 style")
        styles.append(style)
        write_file(stage / "styles" / f"{spec.output_name}.json", raw)

        sprite_base = style.get("sprite")
        if not isinstance(sprite_base, str):
            raise GenerationError(f"{spec.remote_name} has no sprite URL")
        for suffix in (".json", ".png", "@2x.json", "@2x.png"):
            relative = f"sprites/{spec.sprite_directory}/sprite{suffix}"
            write_file(stage / relative, client.bytes(append_url_suffix(sprite_base, suffix)))
            install_files.append(relative)

    font_stacks = sorted(
        stack for style in styles for stack in extract_font_stacks(style)
    )
    font_stacks = sorted(set(font_stacks))
    glyph_template = styles[0].get("glyphs")
    if not isinstance(glyph_template, str):
        raise GenerationError("style has no glyph URL template")

    for font_stack in font_stacks:
        for glyph_range in glyph_ranges:
            url = glyph_template.replace(
                "{fontstack}", quote(font_stack, safe="")
            ).replace("{range}", glyph_range)
            relative = f"glyphs/{font_stack}/{glyph_range}.pbf"
            write_file(stage / relative, client.bytes(url))
            install_files.append(relative)

    return sorted(install_files)


def extract_font_stacks(style: dict[str, Any]) -> set[str]:
    result: set[str] = set()
    layers = style.get("layers")
    if not isinstance(layers, list):
        raise GenerationError("style has no layer list")
    for layer in layers:
        if not isinstance(layer, dict):
            continue
        layout = layer.get("layout")
        if not isinstance(layout, dict):
            continue
        fonts = layout.get("text-font")
        if isinstance(fonts, list) and fonts and all(isinstance(item, str) for item in fonts):
            result.add(",".join(fonts))
    if not result:
        raise GenerationError("no literal font stacks were found in the styles")
    return result


def append_url_suffix(url: str, suffix: str) -> str:
    parts = urlsplit(url)
    return urlunsplit((parts.scheme, parts.netloc, parts.path + suffix,
                       parts.query, parts.fragment))


def create_mbtiles(
    path: Path,
    client: StadiaClient,
    tile_template: str,
    tiles: Sequence[Tile],
    bounds: tuple[float, float, float, float],
    center: tuple[float, float, int],
    min_zoom: int,
    max_zoom: int,
    workers: int,
    tilejson: dict[str, Any],
) -> tuple[int, int]:
    connection = sqlite3.connect(path)
    try:
        connection.executescript(
            """
            CREATE TABLE metadata (name TEXT, value TEXT);
            CREATE TABLE tiles (
              zoom_level INTEGER,
              tile_column INTEGER,
              tile_row INTEGER,
              tile_data BLOB
            );
            CREATE UNIQUE INDEX tile_index
              ON tiles (zoom_level, tile_column, tile_row);
            """
        )
        metadata = {
            "name": "Aucorsa Cordoba Offline Basemap",
            "type": "baselayer",
            "version": "1",
            "description": "Stadia Alidade Smooth vector basemap for Aucorsa",
            "format": "pbf",
            "minzoom": str(min_zoom),
            "maxzoom": str(max_zoom),
            "bounds": ",".join(format_number(item) for item in bounds),
            "center": ",".join(format_number(item) for item in center),
            "attribution": tilejson.get("attribution", ATTRIBUTION),
        }
        vector_layers = tilejson.get("vector_layers")
        if isinstance(vector_layers, list):
            metadata["json"] = json.dumps(
                {"vector_layers": vector_layers}, separators=(",", ":")
            )
        connection.executemany(
            "INSERT INTO metadata (name, value) VALUES (?, ?)",
            metadata.items(),
        )

        populated = 0
        empty = 0
        insert = "INSERT INTO tiles VALUES (?, ?, ?, ?)"
        with ThreadPoolExecutor(max_workers=workers) as executor:
            futures = {
                executor.submit(
                    client.bytes,
                    tile_template.replace("{z}", str(tile.zoom))
                    .replace("{x}", str(tile.x))
                    .replace("{y}", str(tile.y)),
                    "application/vnd.mapbox-vector-tile,application/x-protobuf",
                ): tile
                for tile in tiles
            }
            for completed, future in enumerate(as_completed(futures), start=1):
                tile = futures[future]
                data = future.result()
                if data:
                    tms_row = (1 << tile.zoom) - 1 - tile.y
                    connection.execute(insert, (tile.zoom, tile.x, tms_row, data))
                    populated += 1
                else:
                    empty += 1
                if completed % 50 == 0 or completed == len(futures):
                    print(f"  downloaded {completed}/{len(futures)} tiles")
        connection.commit()
        return populated, empty
    finally:
        connection.close()


def resolve_pmtiles_binary(provided: Path | None) -> Path:
    if provided is not None:
        binary = provided.expanduser().resolve()
        if not binary.is_file():
            raise GenerationError(f"pmtiles CLI does not exist: {binary}")
        return binary

    installed = shutil.which("pmtiles")
    if installed:
        return Path(installed)

    system = platform.system()
    machine = platform.machine().lower()
    architecture = {
        "arm64": "arm64",
        "aarch64": "arm64",
        "x86_64": "x86_64",
        "amd64": "x86_64",
    }.get(machine)
    if architecture is None or system not in {"Darwin", "Linux", "Windows"}:
        raise GenerationError(
            "No bundled pmtiles CLI download is available for "
            f"{system}/{platform.machine()}; use --pmtiles-bin"
        )

    executable_name = "pmtiles.exe" if system == "Windows" else "pmtiles"
    cache_base = Path(
        os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")
    ) / "aucorsa" / "pmtiles" / PMTILES_VERSION
    binary = cache_base / executable_name
    if binary.is_file():
        return binary

    cache_base.mkdir(parents=True, exist_ok=True)
    if system == "Darwin":
        archive_name = f"go-pmtiles-{PMTILES_VERSION}_Darwin_{architecture}.zip"
    else:
        archive_name = f"go-pmtiles_{PMTILES_VERSION}_{system}_{architecture}"
        archive_name += ".zip" if system == "Windows" else ".tar.gz"
    url = (
        "https://github.com/protomaps/go-pmtiles/releases/download/"
        f"v{PMTILES_VERSION}/{archive_name}"
    )
    print(f"Downloading official pmtiles CLI v{PMTILES_VERSION}...")
    archive = download_public(url)
    try:
        if archive_name.endswith(".zip"):
            with zipfile.ZipFile(archive) as package:
                member = next(
                    (name for name in package.namelist()
                     if Path(name).name == executable_name),
                    None,
                )
                if member is None:
                    raise GenerationError("pmtiles release archive has no executable")
                binary.write_bytes(package.read(member))
        else:
            with tarfile.open(archive) as package:
                member = next(
                    (item for item in package.getmembers()
                     if Path(item.name).name == executable_name and item.isfile()),
                    None,
                )
                if member is None:
                    raise GenerationError("pmtiles release archive has no executable")
                extracted = package.extractfile(member)
                if extracted is None:
                    raise GenerationError("could not read pmtiles executable")
                binary.write_bytes(extracted.read())
    finally:
        archive.unlink(missing_ok=True)
    binary.chmod(0o755)
    return binary


def download_public(url: str) -> Path:
    request = Request(url, headers={"User-Agent": USER_AGENT})
    try:
        with urlopen(request, timeout=60) as response:
            data = response.read()
    except (HTTPError, URLError, TimeoutError) as error:
        raise GenerationError(f"Could not download pmtiles CLI: {error}") from error
    handle = tempfile.NamedTemporaryFile(prefix="pmtiles-release-", delete=False)
    try:
        handle.write(data)
        return Path(handle.name)
    finally:
        handle.close()


def convert_to_pmtiles(binary: Path, mbtiles: Path, output: Path) -> None:
    try:
        subprocess.run(
            [str(binary), "convert", str(mbtiles), str(output)],
            check=True,
        )
        subprocess.run(
            [str(binary), "verify", str(output)],
            check=True,
        )
    except (OSError, subprocess.CalledProcessError) as error:
        raise GenerationError(f"pmtiles conversion failed: {error}") from error


def render_manifest(
    generated_at: str,
    package_sha256: str,
    archive_sha256: str,
    archive_size: int,
    install_files: Sequence[str],
    bounds: tuple[float, float, float, float],
    min_zoom: int,
    max_zoom: int,
    populated_tiles: int,
) -> bytes:
    manifest = {
        "schema_version": 1,
        "generator": GENERATOR_ID,
        "generated_at": generated_at,
        "cache_key": package_sha256[:16],
        "package_sha256": package_sha256,
        "archive": {
            "path": "cordoba.pmtiles",
            "sha256": archive_sha256,
            "size": archive_size,
            "bounds": list(bounds),
            "min_zoom": min_zoom,
            "max_zoom": max_zoom,
            "populated_tiles": populated_tiles,
        },
        "install_files": sorted(["cordoba.pmtiles", *install_files]),
    }
    return (json.dumps(manifest, indent=2, ensure_ascii=False) + "\n").encode()


def render_readme(
    generated_at: str,
    host: str,
    logical_bounds: tuple[float, float, float, float],
    bounds: tuple[float, float, float, float],
    center: tuple[float, float, int],
    min_zoom: int,
    max_zoom: int,
    requested_tiles: int,
    populated_tiles: int,
    empty_tiles: int,
    archive_sha256: str,
) -> bytes:
    lines = [
        "# Offline Córdoba basemap",
        "",
        f"- Generated: {generated_at}",
        f"- Endpoint: `{host}`",
        "- Tile source: Stadia Maps OpenMapTiles vector tiles",
        "- Styles: Stadia Alidade Smooth and Alidade Smooth Dark",
        "- Archive: PMTiles v3, MVT with gzip tile compression",
        f"- Zoom levels: {min_zoom}–{max_zoom} "
        "(MapLibre vector-overzooms through app zoom 20)",
        f"- Requested tile slots: {requested_tiles}",
        f"- Populated tiles: {populated_tiles}",
        f"- Empty provider responses: {empty_tiles}",
        f"- Logical bounds: `{format_bounds(logical_bounds)}`",
        f"- Archive bounds: `{format_bounds(bounds)}`",
        f"- Center: `{','.join(format_number(item) for item in center)}`",
        "- `cordoba.pmtiles` SHA-256:",
        f"  `{archive_sha256}`",
        "",
        "Regenerate this directory with:",
        "",
        "```sh",
        "STADIA_MAPS_API_KEY=... python3 tools/generate_offline_map.py",
        "```",
        "",
        "The API key is sent in the authorization header and is never written",
        "to this directory.",
    ]
    return ("\n".join(lines) + "\n").encode()


def write_file(path: Path, data: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(data)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def package_sha256(root: Path, relative_paths: Sequence[str]) -> str:
    digest = hashlib.sha256()
    for relative_path in sorted(relative_paths):
        digest.update(relative_path.encode())
        digest.update(b"\0")
        with (root / relative_path).open("rb") as source:
            for chunk in iter(lambda: source.read(1024 * 1024), b""):
                digest.update(chunk)
        digest.update(b"\0")
    return digest.hexdigest()


def ensure_secret_not_written(root: Path, secret: str) -> None:
    encoded = secret.encode()
    for path in root.rglob("*"):
        if path.is_file() and encoded in path.read_bytes():
            raise GenerationError(f"API key was found in generated file {path.name}")


def format_bounds(bounds: Sequence[float]) -> str:
    return ",".join(format_number(item) for item in bounds)


def format_number(value: float | int) -> str:
    if isinstance(value, int):
        return str(value)
    return format(value, ".15g")


def validate_output_target(output: Path, repo_root: Path, force: bool) -> None:
    output = output.resolve()
    forbidden = {Path(output.anchor), Path.home().resolve(), repo_root.resolve()}
    if output in forbidden:
        raise GenerationError(f"Refusing unsafe output directory: {output}")
    if not output.exists() or force:
        return
    manifest = output / "manifest.json"
    try:
        value = json.loads(manifest.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise GenerationError(
            f"{output} was not created by this generator; use --force to replace it"
        ) from error
    if value.get("generator") != GENERATOR_ID:
        raise GenerationError(
            f"{output} was not created by this generator; use --force to replace it"
        )


def publish(
    stage: Path,
    output: Path,
    staged_bundle: Path,
    bundle_output: Path,
) -> None:
    """Publish the data directory and Flutter bundle as one transaction."""
    output.parent.mkdir(parents=True, exist_ok=True)
    bundle_output.parent.mkdir(parents=True, exist_ok=True)
    output_backup = output.with_name(f".{output.name}.backup-{os.getpid()}")
    bundle_backup = bundle_output.with_name(
        f".{bundle_output.name}.backup-{os.getpid()}"
    )
    for backup in (output_backup, bundle_backup):
        if backup.exists():
            raise GenerationError(f"temporary backup already exists: {backup}")

    output_backed_up = False
    bundle_backed_up = False
    output_published = False
    bundle_published = False
    try:
        if output.exists():
            output.rename(output_backup)
            output_backed_up = True
        if bundle_output.exists():
            bundle_output.rename(bundle_backup)
            bundle_backed_up = True

        stage.rename(output)
        output_published = True
        staged_bundle.rename(bundle_output)
        bundle_published = True
    except BaseException:
        if bundle_published and bundle_output.exists():
            bundle_output.unlink()
        if output_published and output.exists():
            shutil.rmtree(output)
        if bundle_backed_up:
            bundle_backup.rename(bundle_output)
        if output_backed_up:
            output_backup.rename(output)
        raise
    else:
        if output_backup.exists():
            shutil.rmtree(output_backup)
        if bundle_backup.exists():
            bundle_backup.unlink()


def create_flutter_bundle(source: Path, destination: Path) -> None:
    """Package generated data as one optional, root-level Flutter asset."""
    temporary = destination.with_name(f".{destination.name}.generate-{os.getpid()}")
    if temporary.exists():
        raise GenerationError(f"temporary map bundle already exists: {temporary}")

    try:
        with zipfile.ZipFile(
            temporary,
            "w",
            compression=zipfile.ZIP_DEFLATED,
            compresslevel=6,
        ) as bundle:
            for path in sorted(source.rglob("*")):
                if not path.is_file():
                    continue
                compression = (
                    zipfile.ZIP_STORED
                    if path.suffix == ".pmtiles"
                    else zipfile.ZIP_DEFLATED
                )
                bundle.write(
                    path,
                    path.relative_to(source).as_posix(),
                    compress_type=compression,
                )
        os.replace(temporary, destination)
    finally:
        temporary.unlink(missing_ok=True)


def run(argv: Sequence[str] | None = None) -> int:
    args = parse_args(argv)
    script_dir = Path(__file__).resolve().parent
    repo_root = script_dir.parent
    output = (args.output_dir or repo_root / "assets" / "map").expanduser().resolve()
    validate_output_target(output, repo_root, args.force)

    api_key = resolve_api_key(args.api_key)
    host = args.host.rstrip("/")
    tiles = resolve_tiles(args.bounds, args.min_zoom, args.max_zoom, args.ring)
    if not tiles:
        raise GenerationError("tile selection is empty")
    if len(tiles) > args.max_tiles:
        raise GenerationError(
            f"selection contains {len(tiles)} tiles, above --max-tiles={args.max_tiles}"
        )
    if args.workers < 1:
        raise GenerationError("workers must be at least 1")

    bounds = archive_bounds(tiles)
    print(
        f"Generating {len(tiles)} tile slots at zooms "
        f"{args.min_zoom}–{args.max_zoom} for {format_bounds(bounds)}"
    )
    client = StadiaClient(api_key, args.timeout)
    pmtiles_binary = resolve_pmtiles_binary(args.pmtiles_bin)

    output.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(
        prefix=f".{output.name}.generate-",
        dir=output.parent,
    ) as temporary:
        temporary_path = Path(temporary)
        stage = temporary_path / "stage"
        stage.mkdir()

        print("Downloading styles, sprites, and glyphs...")
        install_files = download_style_resources(
            client,
            host,
            stage,
            args.glyph_ranges,
            api_key,
        )

        tilejson = client.json(f"{host}/data/openmaptiles.json")
        if api_key in json.dumps(tilejson):
            raise GenerationError("Stadia returned TileJSON containing the API key")
        templates = tilejson.get("tiles")
        if not isinstance(templates, list) or not templates or not isinstance(templates[0], str):
            raise GenerationError("OpenMapTiles TileJSON has no tile URL template")
        tile_template = urljoin(f"{host}/", templates[0])

        print("Downloading vector tiles...")
        mbtiles = temporary_path / "cordoba.mbtiles"
        populated, empty = create_mbtiles(
            mbtiles,
            client,
            tile_template,
            tiles,
            bounds,
            args.center,
            args.min_zoom,
            args.max_zoom,
            args.workers,
            tilejson,
        )
        if populated == 0:
            raise GenerationError("all vector tile responses were empty")

        print("Converting and verifying PMTiles archive...")
        archive = stage / "cordoba.pmtiles"
        convert_to_pmtiles(pmtiles_binary, mbtiles, archive)
        archive_sha256 = sha256(archive)
        installed_files = sorted(["cordoba.pmtiles", *install_files])
        package_hash = package_sha256(stage, installed_files)
        generated_at = datetime.now(timezone.utc).replace(microsecond=0).isoformat()
        generated_at = generated_at.replace("+00:00", "Z")

        write_file(
            stage / "manifest.json",
            render_manifest(
                generated_at,
                package_hash,
                archive_sha256,
                archive.stat().st_size,
                install_files,
                bounds,
                args.min_zoom,
                args.max_zoom,
                populated,
            ),
        )
        write_file(
            stage / "README.md",
            render_readme(
                generated_at,
                host,
                args.bounds,
                bounds,
                args.center,
                args.min_zoom,
                args.max_zoom,
                len(tiles),
                populated,
                empty,
                archive_sha256,
            ),
        )
        ensure_secret_not_written(stage, api_key)
        bundle = output.parent / "offline_map.zip"
        staged_bundle = temporary_path / "offline_map.zip"
        create_flutter_bundle(stage, staged_bundle)
        publish(stage, output, staged_bundle, bundle)

    print(
        f"Generated {output} with {populated} populated tiles, "
        f"{empty} empty responses, SHA-256 {archive_sha256}. "
        f"Flutter bundle: {bundle}."
    )
    return 0


def main() -> None:
    try:
        raise SystemExit(run())
    except GenerationError as error:
        print(f"error: {error}", file=sys.stderr)
        raise SystemExit(2) from error


if __name__ == "__main__":
    main()
