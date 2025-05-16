import 'package:aucorsa/common/utils/app_localizations_extension.dart';
import 'package:aucorsa/common/utils/bus_line_utils.dart';
import 'package:aucorsa/common/utils/bus_stop_search.dart';
import 'package:aucorsa/common/utils/bus_stop_utils.dart';
import 'package:aucorsa/common/widgets/bus_line_tile.dart';
import 'package:aucorsa/stops/cubits/bus_line_selector_cubit.dart';
import 'package:aucorsa/stops/utils/map_path_bearing_utils.dart';
import 'package:aucorsa/stops/widgets/bus_line_selector_dialog.dart';
import 'package:aucorsa/stops/widgets/bus_stop_dialog.dart';
import 'package:aucorsa/stops/widgets/map_attribution_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class StopsMapPage extends StatefulWidget {
  static const path = '/stops-map';

  const StopsMapPage({super.key});

  @override
  State<StopsMapPage> createState() => _StopsMapPageState();
}

enum _MarkerSize { dot, normal }

class _StopsMapPageState extends State<StopsMapPage> {
  static const hotelCordobaCenterLocation = LatLng(37.8916417, -4.7871324);
  static const thresholdZoom = 15.5;
  static const markerSizeValues = {
    _MarkerSize.dot: 8.0,
    _MarkerSize.normal: 32.0,
  };

  late _MarkerSize markerSize = _MarkerSize.dot;
  late final mapController = MapController();

  late List<BusStopCoordinates> stopCoordinates = [];
  late List<Marker> arrowMarkers = [];
  late List<LatLng> linePath = [];
  late Color? lineColor;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _busLineSelectorListener(
        context,
        context.read<BusLineSelectorCubit>().state,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).brightness == Brightness.light
        ? 'alidade_smooth'
        : 'alidade_smooth_dark';

    final selectedLine = context.watch<BusLineSelectorCubit>().state;

    return BlocListener<BusLineSelectorCubit, String?>(
      listenWhen: (previous, current) => previous != current,
      listener: _busLineSelectorListener,
      child: Scaffold(
        body: Stack(
          children: [
            FlutterMap(
              mapController: mapController,
              options: MapOptions(
                backgroundColor: Theme.of(context).colorScheme.surface,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
                initialCenter: hotelCordobaCenterLocation,
                onPositionChanged: (camera, hasGesture) {
                  if (camera.zoom >= thresholdZoom &&
                      markerSize == _MarkerSize.dot) {
                    setState(() => markerSize = _MarkerSize.normal);
                  } else if (camera.zoom < thresholdZoom &&
                      markerSize == _MarkerSize.normal) {
                    setState(() => markerSize = _MarkerSize.dot);
                  }
                },
                maxZoom: 19,
                minZoom: 11,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tiles.stadiamaps.com/tiles/$style/{z}/{x}/{y}@2x.png?api_key=0a781f97-5aed-4ac9-bcb9-e15c13d65806',
                ),
                if (linePath.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: linePath,
                        color: lineColor!,
                        strokeWidth: 4,
                      ),
                    ],
                  ),
                if (markerSize == _MarkerSize.normal)
                  MarkerLayer(
                    markers: arrowMarkers,
                  ),
                MarkerLayer(
                  markers: [
                    for (final stop in stopCoordinates)
                      Marker(
                        point: stop.value,
                        width: markerSizeValues[markerSize]!,
                        height: markerSizeValues[markerSize]!,
                        child: Material(
                          animationDuration: Duration.zero,
                          color: Theme.of(context).colorScheme.primary,
                          clipBehavior: Clip.antiAlias,
                          shape: const CircleBorder(),
                          elevation: markerSize == _MarkerSize.normal ? 4 : 0,
                          child: markerSize == _MarkerSize.normal
                              ? InkWell(
                                  onTap: () =>
                                      showBusStopDialog(context, stop.key),
                                  child: Icon(
                                    Symbols.directions_bus_rounded,
                                    fill: 1,
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                  ),
                                )
                              : null,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            Positioned(
              top: MediaQuery.paddingOf(context).top + 16,
              left: MediaQuery.paddingOf(context).left + 16,
              right: MediaQuery.paddingOf(context).right + 16,
              height: kToolbarHeight,
              child: Material(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                shape: const StadiumBorder(),
                clipBehavior: Clip.antiAlias,
                elevation: 6,
                child: resolveBusLineSelector(selectedLine),
              ),
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 16,
                children: [
                  FloatingActionButton(
                    tooltip: MaterialLocalizations.of(context).searchFieldLabel,
                    onPressed: () => showBusStopSearch(
                      context: context,
                      stops: BusLineUtils.lines
                          .expand((line) => line.stops)
                          .toSet()
                          .toList(),
                    ),
                    child: const Icon(Symbols.search_rounded),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 2,
              left: 2,
              child: IconButton(
                style: TextButton.styleFrom(
                  foregroundColor:
                      Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                onPressed: () => showMapAttributionDialog(context),
                icon: const Icon(Symbols.info_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> onBusLineSelectorTap() async {
    final busLineSelectorCubit = context.read<BusLineSelectorCubit>();

    final selectedLine = await showBusLineSelector(context);

    if (selectedLine == busLineSelectorCubit.state) {
      return busLineSelectorCubit.clear();
    }

    if (selectedLine == null) return;

    return busLineSelectorCubit.selectBusLine(selectedLine);
  }

  Widget resolveBusLineSelector(String? selectedLine) {
    const listTilePadding = EdgeInsets.only(left: 8, right: 4);

    return MediaQuery.removePadding(
      context: context,
      removeLeft: true,
      removeRight: true,
      child: InkWell(
        onTap: onBusLineSelectorTap,
        child: selectedLine == null
            ? ListTile(
                contentPadding: listTilePadding,
                leading: CircleAvatar(
                  backgroundColor:
                      Theme.of(context).colorScheme.secondaryContainer,
                  foregroundColor:
                      Theme.of(context).colorScheme.onSecondaryContainer,
                  child: const Icon(Symbols.signpost_rounded, fill: 0.5),
                ),
                title: Text(
                  context.l10n.allStops,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                trailing: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(
                    Symbols.keyboard_arrow_down_rounded,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            : BusLineTile(
                lineId: selectedLine,
                padding: listTilePadding,
                onTap: onBusLineSelectorTap,
                trailing: IconButton(
                  icon: const Icon(Symbols.close_rounded),
                  onPressed: context.read<BusLineSelectorCubit>().clear,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
      ),
    );
  }

  void _busLineSelectorListener(BuildContext context, String? selectedLine) =>
      setState(() {
        linePath = BusLineUtils.getLinePath(selectedLine);

        if (selectedLine != null) {
          lineColor = BusLineTile.resolveLineBackgroundColor(
            context,
            BusLineUtils.getLine(selectedLine).color,
          );
        }

        stopCoordinates = BusLineUtils.lines
            .where((line) => selectedLine == null || line.id == selectedLine)
            .map((line) => line.stops)
            .expand((stop) => stop)
            .toSet()
            .map(BusStopUtils.resolveCoordinates)
            .whereType<BusStopCoordinates>()
            .toList();

        if (selectedLine != null) {
          arrowMarkers = MapPathBearingUtils.resolveArrowMarkers(
            context: context,
            path: linePath,
            color: lineColor!,
          );
        }
      });
}
