#!/usr/bin/env python3
"""Download AUCORSA transit data and generate the Flutter data utilities."""

from __future__ import annotations

import argparse
import html
import json
import math
import re
import shutil
import subprocess
import sys
import tempfile
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass, replace
from decimal import Decimal, InvalidOperation
from pathlib import Path
from typing import Any, Iterable, Sequence
from urllib.error import HTTPError, URLError
from urllib.parse import urlencode
from urllib.request import Request, urlopen


DEFAULT_BASE_URL = "https://aucorsa.es"
USER_AGENT = "aucorsa-flutter-transit-updater/1.0"
NONCE_PATTERN = re.compile(r'"ajax_nonce"\s*:\s*"([^"]+)"')
HOMEPAGE_POST_ID_PATTERN = re.compile(
    r"var\s+ajax_vars\s*=\s*\{.*?\"post_id\":\"?(\d+)\"?",
    re.DOTALL,
)
MAP_ID_PATTERN = re.compile(
    r'<[^>]+\bid=["\']map["\'][^>]+\bdata-line-id=["\'](\d+)["\']',
    re.IGNORECASE,
)
ROUTE_PHASE_PATTERN = re.compile(
    r'<[^>]+\bclass=["\'][^"\']*(?<![-\w])route-phase(?![-\w])[^"\']*["\'][^>]*>'
    r'(.*?)</[^>]+>',
    re.IGNORECASE | re.DOTALL,
)
TAG_PATTERN = re.compile(r"<[^>]+>")
COLOR_PATTERN = re.compile(r"^#[0-9a-fA-F]{6}$")
MINIMUM_LINE_COUNT = 20
MINIMUM_STOP_COUNT = 500
MAX_STOP_COORDINATE_DIFFERENCE_METERS = 50
COORDINATE_QUANTUM = Decimal("0.0000000000001")


class UpdateError(RuntimeError):
    """Raised when downloaded data is incomplete or has an unknown shape."""


@dataclass(frozen=True)
class LineSpec:
    id: str
    post_id: int | None = None
    event_id: str | None = None
    discovered_name: str | None = None
    name_override: str | None = None


@dataclass(frozen=True)
class LinePage:
    spec: LineSpec
    post_id: int
    name: str


@dataclass(frozen=True)
class LineData:
    id: str
    name: str
    color: str
    stops: tuple[int, ...]
    path: tuple[tuple[Decimal, Decimal], ...]
    stop_coordinates: dict[int, tuple[Decimal, Decimal]]
    event_id: str | None = None


class AucorsaClient:
    def __init__(self, base_url: str, timeout: float) -> None:
        self.base_url = base_url.rstrip("/")
        self.timeout = timeout

    def text(self, path: str, params: dict[str, object] | None = None) -> str:
        url = self._url(path, params)
        request = Request(
            url,
            headers={
                "Accept": "text/html,application/json",
                "Referer": f"{self.base_url}/",
                "User-Agent": USER_AGENT,
            },
        )

        for attempt in range(3):
            try:
                with urlopen(request, timeout=self.timeout) as response:
                    encoding = response.headers.get_content_charset() or "utf-8"
                    return response.read().decode(encoding)
            except HTTPError as error:
                if error.code not in {429, 500, 502, 503, 504} or attempt == 2:
                    raise UpdateError(f"GET {url} failed with HTTP {error.code}") from error
            except (TimeoutError, URLError) as error:
                if attempt == 2:
                    raise UpdateError(f"GET {url} failed: {error}") from error

            time.sleep(2**attempt)

        raise AssertionError("unreachable")

    def json(
        self, path: str, params: dict[str, object] | None = None
    ) -> Any:
        body = self.text(path, params)
        try:
            return json.loads(body, parse_float=Decimal)
        except json.JSONDecodeError as error:
            raise UpdateError(f"GET {path} returned invalid JSON") from error

    def _url(self, path: str, params: dict[str, object] | None) -> str:
        url = f"{self.base_url}/{path.lstrip('/')}"
        if params:
            url = f"{url}?{urlencode(params)}"
        return url


def parse_args(argv: Sequence[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--base-url",
        default=DEFAULT_BASE_URL,
        help=f"AUCORSA website root (default: {DEFAULT_BASE_URL})",
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="download and validate data, but fail instead of changing stale files",
    )
    parser.add_argument(
        "--timeout",
        type=float,
        default=30,
        help="per-request timeout in seconds (default: 30)",
    )
    parser.add_argument(
        "--workers",
        type=int,
        default=8,
        help="maximum simultaneous requests (default: 8)",
    )
    return parser.parse_args(argv)


def load_config(path: Path) -> tuple[list[LineSpec], list[str], dict[str, str]]:
    try:
        raw = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise UpdateError(f"Could not read {path}: {error}") from error

    extras = raw.get("extra_lines")
    if not isinstance(extras, list):
        raise UpdateError(f"{path} must contain an extra_lines list")
    preferred_order = raw.get("preferred_discovered_line_order")
    if not isinstance(preferred_order, list) or not all(
        isinstance(line_id, str) for line_id in preferred_order
    ):
        raise UpdateError(
            f"{path} must contain a preferred_discovered_line_order string list"
        )
    if len(preferred_order) != len(set(preferred_order)):
        raise UpdateError(f"{path} contains duplicate preferred line IDs")
    name_overrides = raw.get("discovered_line_name_overrides")
    if not isinstance(name_overrides, dict) or not all(
        isinstance(line_id, str)
        and isinstance(name, str)
        and bool(name.strip())
        for line_id, name in name_overrides.items()
    ):
        raise UpdateError(
            f"{path} must contain a discovered_line_name_overrides string map"
        )

    result: list[LineSpec] = []
    for entry in extras:
        if not isinstance(entry, dict) or not isinstance(entry.get("id"), str):
            raise UpdateError(f"Invalid extra line entry in {path}: {entry!r}")
        event_id = entry.get("event_id")
        if event_id is not None and not isinstance(event_id, str):
            raise UpdateError(f"Invalid event_id for line {entry['id']}")
        name = entry.get("name")
        if not isinstance(name, str) or not name.strip():
            raise UpdateError(f"Extra line {entry['id']} must have a display name")
        result.append(
            LineSpec(
                id=entry["id"],
                event_id=event_id,
                name_override=name.strip(),
            )
        )
    return result, preferred_order, name_overrides


def apply_preferred_order(
    lines: Sequence[LineSpec], preferred_order: Sequence[str]
) -> list[LineSpec]:
    rank = {line_id: index for index, line_id in enumerate(preferred_order)}
    original_rank = {line.id: index for index, line in enumerate(lines)}
    return sorted(
        lines,
        key=lambda line: (
            rank.get(line.id, len(rank)),
            original_rank[line.id],
        ),
    )


def parse_nonce(homepage: str) -> str:
    match = NONCE_PATTERN.search(homepage)
    if match is None:
        raise UpdateError("Could not find ajax_nonce on the AUCORSA homepage")
    return match.group(1)


def parse_homepage_post_id(homepage: str) -> int:
    match = HOMEPAGE_POST_ID_PATTERN.search(homepage)
    if match is None:
        raise UpdateError("Could not find post_id on the AUCORSA homepage")
    return int(match.group(1))


def parse_discovered_lines(payload: Any) -> list[LineSpec]:
    if not isinstance(payload, list):
        raise UpdateError("The line autocomplete endpoint did not return a list")

    result: list[LineSpec] = []
    for entry in payload:
        if not isinstance(entry, dict):
            raise UpdateError("The line autocomplete response contains a non-object")
        label = entry.get("label")
        post_id = entry.get("id")
        if not isinstance(label, str) or not isinstance(post_id, int):
            raise UpdateError(f"Invalid line autocomplete entry: {entry!r}")

        if "ㅤ" in label:
            line_id, name = label.split("ㅤ", 1)
        else:
            match = re.match(r"^(\S+)\s+(.+)$", label.strip())
            if match is None:
                raise UpdateError(f"Could not split line autocomplete label {label!r}")
            line_id, name = match.groups()

        result.append(
            LineSpec(
                id=line_id.strip().upper(),
                post_id=post_id,
                discovered_name=readable_name(name),
            )
        )
    return result


def parse_line_page(page: str, spec: LineSpec) -> LinePage:
    map_match = MAP_ID_PATTERN.search(page)
    if map_match is None:
        raise UpdateError(f"Line {spec.id}: page does not expose a map data-line-id")
    post_id = int(map_match.group(1))
    if spec.post_id is not None and spec.post_id != post_id:
        raise UpdateError(
            f"Line {spec.id}: autocomplete post ID {spec.post_id} does not match "
            f"page map ID {post_id}"
        )

    phases = []
    for match in ROUTE_PHASE_PATTERN.finditer(page):
        text = TAG_PATTERN.sub(" ", match.group(1))
        text = " ".join(html.unescape(text).split())
        if text:
            phases.append(readable_name(text))

    name = spec.name_override or " - ".join(phases) or spec.discovered_name
    if not name:
        raise UpdateError(f"Line {spec.id}: page does not contain a route name")
    return LinePage(spec=spec, post_id=post_id, name=name)


def readable_name(value: str) -> str:
    """Convert the site's all-caps labels to app-friendly capitalization."""
    segments = []
    for segment in value.strip().split(" - "):
        if segment == segment.upper():
            words = segment.lower().title().split()
            for index, word in enumerate(words[1:], start=1):
                if word in {"De", "Del", "La", "Las", "Los", "Y"}:
                    words[index] = word.lower()
            segment = " ".join(words)
        segments.append(segment)
    result = " - ".join(segments)
    return re.sub(r"\b([A-ZÁÉÍÓÚÑ]\.)(?=\w)", r"\1 ", result)


def parse_stop_names(payload: Any) -> dict[int, str]:
    if not isinstance(payload, list):
        raise UpdateError("The stop autocomplete endpoint did not return a list")

    names: dict[int, str] = {}
    for entry in payload:
        if not isinstance(entry, dict):
            raise UpdateError("The stop autocomplete response contains a non-object")
        raw_id = entry.get("id")
        label = entry.get("label")
        try:
            stop_id = int(raw_id)
        except (TypeError, ValueError) as error:
            raise UpdateError(f"Invalid stop ID {raw_id!r}") from error
        if not isinstance(label, str):
            raise UpdateError(f"Stop {stop_id} has no label")

        suffix = f" ({stop_id})"
        name = label[: -len(suffix)] if label.endswith(suffix) else label
        name = " ".join(html.unescape(name).split())
        if not name:
            raise UpdateError(f"Stop {stop_id} has an empty name")
        names[stop_id] = name
    return names


def parse_line_data(page: LinePage, payload: Any) -> LineData:
    if not isinstance(payload, list) or not payload:
        raise UpdateError(f"Line {page.spec.id}: map endpoint returned no routes")

    stops: list[int] = []
    seen_stops: set[int] = set()
    coordinates: dict[int, tuple[Decimal, Decimal]] = {}
    path: list[tuple[Decimal, Decimal]] = []
    colors: list[str] = []

    for feature in iter_features(payload):
        geometry = feature.get("geometry")
        if not isinstance(geometry, dict):
            continue
        geometry_type = geometry.get("type")
        raw_coordinates = geometry.get("coordinates")

        if geometry_type == "Point":
            try:
                stop_id = int(feature.get("id"))
                longitude, latitude = coordinate_pair(raw_coordinates)
            except (TypeError, ValueError, UpdateError) as error:
                raise UpdateError(
                    f"Line {page.spec.id}: invalid stop feature {feature!r}"
                ) from error
            if stop_id not in seen_stops:
                seen_stops.add(stop_id)
                stops.append(stop_id)
            previous = coordinates.get(stop_id)
            point = (latitude, longitude)
            if previous is not None and previous != point:
                raise UpdateError(
                    f"Line {page.spec.id}: stop {stop_id} has conflicting coordinates"
                )
            coordinates[stop_id] = point

        elif geometry_type == "LineString":
            if not isinstance(raw_coordinates, list):
                raise UpdateError(f"Line {page.spec.id}: invalid LineString coordinates")
            path.extend(
                (latitude, longitude)
                for longitude, latitude in map(coordinate_pair, raw_coordinates)
            )
            properties = feature.get("properties")
            if isinstance(properties, dict):
                style = properties.get("style")
                if isinstance(style, dict) and isinstance(style.get("color"), str):
                    colors.append(style["color"])

    if not stops:
        raise UpdateError(f"Line {page.spec.id}: map contains no stops")
    if not path:
        raise UpdateError(f"Line {page.spec.id}: map contains no route geometry")
    if not colors or not COLOR_PATTERN.fullmatch(colors[0]):
        raise UpdateError(f"Line {page.spec.id}: map contains no valid line color")
    if any(color.lower() != colors[0].lower() for color in colors):
        raise UpdateError(f"Line {page.spec.id}: route geometries use different colors")

    return LineData(
        id=page.spec.id,
        name=page.name,
        color=colors[0][1:].upper(),
        stops=tuple(stops),
        path=tuple(path),
        stop_coordinates=coordinates,
        event_id=page.spec.event_id,
    )


def iter_features(value: Any) -> Iterable[dict[str, Any]]:
    if isinstance(value, list):
        for item in value:
            yield from iter_features(item)
        return
    if not isinstance(value, dict):
        return
    if value.get("type") == "Feature" and isinstance(value.get("geometry"), dict):
        yield value
    features = value.get("features")
    if isinstance(features, list):
        for feature in features:
            yield from iter_features(feature)


def coordinate_pair(value: Any) -> tuple[Decimal, Decimal]:
    if not isinstance(value, list) or len(value) < 2:
        raise UpdateError(f"Invalid coordinate pair {value!r}")
    try:
        longitude = Decimal(str(value[0])).quantize(COORDINATE_QUANTUM)
        latitude = Decimal(str(value[1])).quantize(COORDINATE_QUANTUM)
    except (InvalidOperation, ValueError) as error:
        raise UpdateError(f"Invalid coordinate pair {value!r}") from error
    if not (-180 <= longitude <= 180 and -90 <= latitude <= 90):
        raise UpdateError(f"Coordinate pair outside valid bounds: {value!r}")
    return longitude, latitude


def merge_stop_coordinates(
    lines: Sequence[LineData],
) -> dict[int, tuple[Decimal, Decimal]]:
    result: dict[int, tuple[Decimal, Decimal]] = {}
    for line in lines:
        for stop_id, point in line.stop_coordinates.items():
            previous = result.get(stop_id)
            if previous is not None and previous != point:
                distance = coordinate_distance_meters(previous, point)
                if distance > MAX_STOP_COORDINATE_DIFFERENCE_METERS:
                    raise UpdateError(
                        f"Stop {stop_id} differs by {distance:.1f} metres across lines: "
                        f"{previous!r} and {point!r}"
                    )
                continue
            result[stop_id] = point
    return result


def coordinate_distance_meters(
    first: tuple[Decimal, Decimal], second: tuple[Decimal, Decimal]
) -> float:
    """Return an adequate short-distance approximation for validation."""
    latitude = math.radians(float((first[0] + second[0]) / 2))
    latitude_delta = float(first[0] - second[0]) * 111_320
    longitude_delta = float(first[1] - second[1]) * 111_320 * math.cos(latitude)
    return math.hypot(latitude_delta, longitude_delta)


def validate_dataset(
    lines: Sequence[LineData],
    stop_names: dict[int, str],
    stop_coordinates: dict[int, tuple[Decimal, Decimal]],
) -> None:
    if len(lines) < MINIMUM_LINE_COUNT:
        raise UpdateError(
            f"Refusing to generate only {len(lines)} lines; expected at least "
            f"{MINIMUM_LINE_COUNT}"
        )
    if len(stop_coordinates) < MINIMUM_STOP_COUNT:
        raise UpdateError(
            f"Refusing to generate only {len(stop_coordinates)} stops; expected at least "
            f"{MINIMUM_STOP_COUNT}"
        )

    line_ids = [line.id for line in lines]
    duplicate_lines = sorted({line_id for line_id in line_ids if line_ids.count(line_id) > 1})
    if duplicate_lines:
        raise UpdateError(f"Duplicate line IDs: {', '.join(duplicate_lines)}")

    referenced_stops = {stop_id for line in lines for stop_id in line.stops}
    missing_names = sorted(referenced_stops - stop_names.keys())
    missing_coordinates = sorted(referenced_stops - stop_coordinates.keys())
    if missing_names:
        raise UpdateError(f"Stops without names: {missing_names}")
    if missing_coordinates:
        raise UpdateError(f"Stops without coordinates: {missing_coordinates}")


def dart_string(value: str) -> str:
    return (
        value.replace("\\", "\\\\")
        .replace("'", "\\'")
        .replace("$", "\\$")
        .replace("\r", "\\r")
        .replace("\n", "\\n")
    )


def dart_decimal(value: Decimal) -> str:
    result = format(value, "f").rstrip("0").rstrip(".")
    if result in {"", "-0"}:
        return "0"
    return result


def render_bus_line_utils(lines: Sequence[LineData]) -> str:
    chunks = [
        "// GENERATED CODE - DO NOT MODIFY BY HAND.\n",
        "// Run: python3 tools/update_transit_data.py\n\n",
        "import 'dart:ui';\n\n",
        "import 'package:aucorsa/common/models/bus_line.dart';\n",
        "import 'package:aucorsa/events/models/event_id.dart';\n",
        "import 'package:aucorsa/events/models/events_calendar.dart';\n",
        "import 'package:latlong2/latlong.dart';\n\n",
        "class BusLineUtils {\n",
        "  const BusLineUtils._();\n\n",
        "  static BusLine getLine(String id) =>\n",
        "      lines.singleWhere((line) => line.id == id);\n\n",
        "  static List<LatLng> getLinePath(String? stopId) =>\n",
        "      linePaths[stopId] ?? [];\n\n",
        "  static bool isLineAvailable(String id) =>\n",
        "      lines.any((line) => line.id == id);\n\n",
        "  static int getStopsLength(int stopId) =>\n",
        "      lines.where((line) => line.stops.contains(stopId)).length;\n\n",
        "  static List<String> getLinesByStop(int stopId) => lines\n",
        "      .where((line) => line.stops.contains(stopId))\n",
        "      .map((line) => line.id)\n",
        "      .toList();\n\n",
        "  static int getLineIndex(String lineId) =>\n",
        "      lines.indexWhere((line) => line.id == lineId);\n\n",
        "  static final _currentEvents = EventsCalendar.currentEvents.map(\n",
        "    (event) => event.id,\n",
        "  );\n\n",
        "  static final lines =\n",
        "      [\n",
    ]

    for line in lines:
        chunks.extend(
            [
                "        const BusLine(\n",
                f"          id: '{dart_string(line.id)}',\n",
                f"          name: '{dart_string(line.name)}',\n",
                f"          color: Color(0xFF{line.color}),\n",
            ]
        )
        if line.event_id is not None:
            chunks.append(f"          eventId: EventId.{line.event_id},\n")
        chunks.append("          stops: [\n")
        chunks.extend(f"            {stop_id},\n" for stop_id in line.stops)
        chunks.extend(["          ],\n", "        ),\n"])

    chunks.extend(
        [
            "      ]\n",
            "          .where(\n",
            "            (line) =>\n",
            "                line.eventId == null || _currentEvents.contains(line.eventId),\n",
            "          )\n",
            "          .toList();\n\n",
            "  static const linePaths = {\n",
        ]
    )
    for line in lines:
        chunks.append(f"    '{dart_string(line.id)}': [\n")
        chunks.extend(
            "      LatLng("
            f"{dart_decimal(latitude)}, {dart_decimal(longitude)}),\n"
            for latitude, longitude in line.path
        )
        chunks.append("    ],\n")
    chunks.extend(["  };\n", "}\n"])
    return "".join(chunks)


def render_bus_stop_utils(
    stop_names: dict[int, str],
    stop_coordinates: dict[int, tuple[Decimal, Decimal]],
) -> str:
    chunks = [
        "// GENERATED CODE - DO NOT MODIFY BY HAND.\n",
        "// Run: python3 tools/update_transit_data.py\n\n",
        "import 'package:latlong2/latlong.dart';\n\n",
        "typedef BusStopCoordinates = MapEntry<int, LatLng>;\n\n",
        "class BusStopUtils {\n",
        "  const BusStopUtils._();\n\n",
        "  static String resolveName(int stopId) => _busStopNames[stopId] ?? '';\n\n",
        "  static BusStopCoordinates? resolveCoordinates(int stopId) {\n",
        "    final coordinates = _busStopCoordinates[stopId];\n\n",
        "    if (coordinates == null) return null;\n\n",
        "    return MapEntry(stopId, coordinates);\n",
        "  }\n\n",
        "  static const _busStopCoordinates = {\n",
    ]
    for stop_id in sorted(stop_coordinates):
        latitude, longitude = stop_coordinates[stop_id]
        chunks.append(
            f"    {stop_id}: LatLng({dart_decimal(latitude)}, "
            f"{dart_decimal(longitude)}),\n"
        )
    chunks.extend(["  };\n\n", "  static const _busStopNames = {\n"])
    for stop_id in sorted(stop_coordinates):
        chunks.append(f"    {stop_id}: '{dart_string(stop_names[stop_id])}',\n")
    chunks.extend(["  };\n", "}\n"])
    return "".join(chunks)


def write_atomically(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(
        "w",
        encoding="utf-8",
        dir=path.parent,
        prefix=f".{path.name}.",
        delete=False,
    ) as temporary:
        temporary.write(content)
        temporary_path = Path(temporary.name)
    temporary_path.replace(path)


def format_outputs(outputs: dict[Path, str]) -> dict[Path, str]:
    dart = shutil.which("dart")
    if dart is None:
        print("warning: dart is not installed; generated files were not formatted", file=sys.stderr)
        return outputs

    with tempfile.TemporaryDirectory(prefix="aucorsa-transit-data-") as directory:
        temporary_paths: dict[Path, Path] = {}
        for index, (path, content) in enumerate(outputs.items()):
            temporary_path = Path(directory) / f"{index}-{path.name}"
            temporary_path.write_text(content, encoding="utf-8")
            temporary_paths[path] = temporary_path

        result = subprocess.run(
            [dart, "format", *(str(path) for path in temporary_paths.values())],
            check=False,
            text=True,
            capture_output=True,
        )
        if result.returncode != 0:
            raise UpdateError(f"dart format failed:\n{result.stderr.strip()}")
        return {
            path: temporary_path.read_text(encoding="utf-8")
            for path, temporary_path in temporary_paths.items()
        }


def download_pages(
    client: AucorsaClient, specs: Sequence[LineSpec], workers: int
) -> list[LinePage]:
    pages: dict[str, LinePage] = {}
    with ThreadPoolExecutor(max_workers=workers) as executor:
        futures = {
            executor.submit(client.text, f"/linea/{spec.id.lower()}/"): spec
            for spec in specs
        }
        for future in as_completed(futures):
            spec = futures[future]
            pages[spec.id] = parse_line_page(future.result(), spec)
    return [pages[spec.id] for spec in specs]


def download_line_data(
    client: AucorsaClient,
    pages: Sequence[LinePage],
    nonce: str,
    workers: int,
) -> list[LineData]:
    lines: dict[str, LineData] = {}
    with ThreadPoolExecutor(max_workers=workers) as executor:
        futures = {
            executor.submit(
                client.json,
                "/wp-json/aucorsa/v1/map/nodes",
                {"line_id": page.post_id, "mode": "complete", "_wpnonce": nonce},
            ): page
            for page in pages
        }
        for future in as_completed(futures):
            page = futures[future]
            lines[page.spec.id] = parse_line_data(page, future.result())
    return [lines[page.spec.id] for page in pages]


def run(argv: Sequence[str] | None = None) -> int:
    args = parse_args(argv)
    if args.timeout <= 0:
        raise UpdateError("--timeout must be greater than zero")
    if args.workers <= 0:
        raise UpdateError("--workers must be greater than zero")

    script_dir = Path(__file__).resolve().parent
    repo_root = script_dir.parent
    client = AucorsaClient(args.base_url, args.timeout)

    print("Downloading AUCORSA metadata...")
    homepage = client.text("/")
    nonce = parse_nonce(homepage)
    homepage_post_id = parse_homepage_post_id(homepage)
    discovered = parse_discovered_lines(
        client.json(
            "/wp-json/aucorsa/v1/autocompletion/line",
            {"term": "", "_wpnonce": nonce},
        )
    )
    extras, preferred_order, name_overrides = load_config(
        script_dir / "transit_lines.json"
    )
    discovered = apply_preferred_order(discovered, preferred_order)
    unknown_overrides = sorted(name_overrides.keys() - {line.id for line in discovered})
    if unknown_overrides:
        raise UpdateError(
            "Name overrides refer to undiscovered lines: " + ", ".join(unknown_overrides)
        )
    discovered = [
        replace(line, name_override=name_overrides.get(line.id)) for line in discovered
    ]
    specs = [*discovered, *extras]

    duplicate_ids = sorted(
        {spec.id for spec in specs if sum(item.id == spec.id for item in specs) > 1}
    )
    if duplicate_ids:
        raise UpdateError(
            "Lines are both discovered and configured as extras: " + ", ".join(duplicate_ids)
        )

    print(f"Downloading {len(specs)} line pages and maps...")
    pages = download_pages(client, specs, args.workers)
    lines = download_line_data(client, pages, nonce, args.workers)
    stop_names = parse_stop_names(
        client.json(
            "/wp-json/aucorsa/v1/autocompletion/stop",
            {
                "post_id": homepage_post_id,
                "line_number": "",
                "_wpnonce": nonce,
            },
        )
    )
    stop_coordinates = merge_stop_coordinates(lines)
    validate_dataset(lines, stop_names, stop_coordinates)

    outputs = format_outputs({
        repo_root / "lib/common/utils/bus_line_utils.dart": render_bus_line_utils(lines),
        repo_root / "lib/common/utils/bus_stop_utils.dart": render_bus_stop_utils(
            stop_names, stop_coordinates
        ),
    })

    stale = [
        path
        for path, content in outputs.items()
        if not path.exists() or path.read_text(encoding="utf-8") != content
    ]
    if args.check:
        if stale:
            print("Generated transit data is stale:", file=sys.stderr)
            for path in stale:
                print(f"  {path.relative_to(repo_root)}", file=sys.stderr)
            return 1
        print("Generated transit data is current.")
        return 0

    for path, content in outputs.items():
        write_atomically(path, content)

    total_points = sum(len(line.path) for line in lines)
    print(
        f"Updated {len(lines)} lines, {len(stop_coordinates)} stops, "
        f"and {total_points} route points."
    )
    return 0


def main() -> None:
    try:
        raise SystemExit(run())
    except UpdateError as error:
        print(f"error: {error}", file=sys.stderr)
        raise SystemExit(2) from error


if __name__ == "__main__":
    main()
