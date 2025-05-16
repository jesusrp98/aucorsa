import 'package:aucorsa/common/utils/bus_line_utils.dart';
import 'package:aucorsa/common/utils/bus_stop_search.dart';
import 'package:aucorsa/common/utils/bus_stop_utils.dart';
import 'package:aucorsa/common/utils/urls.dart';
import 'package:aucorsa/common/widgets/bus_line_tile.dart';
import 'package:aucorsa/stops/cubits/bus_line_selector_cubit.dart';
import 'package:aucorsa/stops/utils/map_marker_size.dart';
import 'package:aucorsa/stops/utils/map_path_bearing_utils.dart';
import 'package:aucorsa/stops/widgets/bus_line_selector_bar.dart';
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

class _StopsMapPageState extends State<StopsMapPage> {
  static const hotelCordobaCenterLocation = LatLng(37.8916417, -4.7871324);
  static const thresholdZoom = 15.5;
  static const markerSizeValues = {
    MapMarkerSize.dot: 8.0,
    MapMarkerSize.normal: 32.0,
  };

  late MapMarkerSize markerSize = MapMarkerSize.dot;
  late final mapController = MapController();

  late List<BusStopCoordinates> stopCoordinates = [];
  late List<Marker> arrowMarkers = [];
  late List<LatLng> linePath = [];
  late Color? lineColor;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => busLineSelectorListener(
        context,
        context.read<BusLineSelectorCubit>().state,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedLine = context.watch<BusLineSelectorCubit>().state;

    return BlocListener<BusLineSelectorCubit, String?>(
      listenWhen: (previous, current) => previous != current,
      listener: busLineSelectorListener,
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
                onPositionChanged: onPositionChanged,
                maxZoom: 19,
                minZoom: 11,
              ),
              children: [
                TileLayer(
                  urlTemplate: Urls.resolveMapStyleUrl(
                    brightness: Theme.of(context).brightness,
                    apiKey: '0a781f97-5aed-4ac9-bcb9-e15c13d65806',
                  ),
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
                if (markerSize == MapMarkerSize.normal)
                  MarkerLayer(markers: arrowMarkers),
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
                          elevation: markerSize == MapMarkerSize.normal ? 4 : 0,
                          child: markerSize == MapMarkerSize.normal
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
              child: BusLineSelectorBar(
                selectedLine: selectedLine,
                onTap: onBusLineSelectorTap,
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

  void onPositionChanged(MapCamera camera, bool _) {
    if (camera.zoom >= thresholdZoom && markerSize == MapMarkerSize.dot) {
      setState(() => markerSize = MapMarkerSize.normal);
    } else if (camera.zoom < thresholdZoom &&
        markerSize == MapMarkerSize.normal) {
      setState(() => markerSize = MapMarkerSize.dot);
    }
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

  void busLineSelectorListener(BuildContext context, String? selectedLine) =>
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
