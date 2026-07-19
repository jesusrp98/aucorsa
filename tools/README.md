# Transit data updater

`update_transit_data.py` replaces the old Colab notebooks. It downloads the
current line, stop, coordinate, color, and route geometry data from AUCORSA and
writes these app files directly:

- `lib/common/utils/bus_line_utils.dart`
- `lib/common/utils/bus_stop_utils.dart`

Run it from any directory inside or outside the repository:

```sh
python3 tools/update_transit_data.py
```

The script uses only Python's standard library. After downloading everything,
it validates that every referenced stop has a name and coordinates. Files are
written atomically only after the full dataset passes validation. If `dart` is
available, the generated files are formatted automatically.

To check whether committed files match the current server data without writing:

```sh
python3 tools/update_transit_data.py --check
```

Active lines are discovered from AUCORSA. Lines omitted by that endpoint but
still supported by the app are declared in `transit_lines.json`. This currently
includes football lines 71–75, airport line 78, and the Feria-only lines, with
their `EventId` value.
The config also keeps the app's user-facing line order stable; newly discovered
lines that are not listed there are appended automatically. Extra lines keep a
short display name in the config because AUCORSA omits their metadata from the
line-discovery endpoint; their stops, colors, coordinates, and paths still come
from the server. Three regular-line display-name overrides join words that the
website splits across visual-only heading lines.

Useful options:

```sh
python3 tools/update_transit_data.py --help
python3 tools/update_transit_data.py --workers 4 --timeout 45
```
