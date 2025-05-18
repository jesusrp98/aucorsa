import 'package:aucorsa/common/utils/bus_line_utils.dart';
import 'package:aucorsa/common/utils/bus_stop_search.dart';
import 'package:aucorsa/common/utils/urls.dart';
import 'package:aucorsa/stops/cubits/bus_line_selector_cubit.dart';
import 'package:aucorsa/stops/utils/map_marker_size.dart';
import 'package:aucorsa/stops/widgets/bus_stop_dialog.dart';
import 'package:aucorsa/stops/widgets/map_attribution_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class AucorsaMap extends StatefulWidget {
  const AucorsaMap({super.key});

  @override
  State<AucorsaMap> createState() => _AucorsaMapState();
}

class _AucorsaMapState extends State<AucorsaMap> {
  static const hotelCordobaCenterLocation = LatLng(37.8916417, -4.7871324);
  static const thresholdZoom = 15.5;
  static const markerSizeValues = {
    MapMarkerSize.dot: 8.0,
    MapMarkerSize.normal: 32.0,
  };

  late MapMarkerSize markerSize = MapMarkerSize.dot;
  late final mapController = MapController();

  @override
  Widget build(BuildContext context) {
    final busLineSelectorState = context.watch<BusLineSelectorCubit>().state;
    final padding = MediaQuery.paddingOf(context);

    return Stack(
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
                apiKey: dotenv.env['CHART_STYLE_API_KEY']!,
              ),
            ),
            if (busLineSelectorState.linePath.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: busLineSelectorState.linePath,
                    color: busLineSelectorState.lineColor!,
                    strokeWidth: 4,
                  ),
                ],
              ),
            if (markerSize == MapMarkerSize.normal)
              MarkerLayer(markers: busLineSelectorState.arrowMarkers),
            MarkerLayer(
              markers: [
                for (final stop in busLineSelectorState.stopCoordinates)
                  Marker(
                    point: stop.value,
                    width: markerSizeValues[markerSize]!,
                    height: markerSizeValues[markerSize]!,
                    child: Material(
                      animationDuration: Duration.zero,
                      color: Theme.of(context).colorScheme.primaryFixed,
                      clipBehavior: Clip.antiAlias,
                      shape: const CircleBorder(),
                      elevation: markerSize == MapMarkerSize.normal ? 4 : 0,
                      child: markerSize == MapMarkerSize.normal
                          ? InkWell(
                              onTap: () => showBusStopDialog(context, stop.key),
                              child: Icon(
                                Symbols.directions_bus_rounded,
                                fill: 1,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryFixed,
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
          bottom: 16 + padding.bottom,
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
          bottom: 2 + padding.bottom,
          left: 2,
          child: IconButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            onPressed: () => showMapAttributionDialog(context),
            icon: const Icon(Symbols.info_rounded),
          ),
        ),
      ],
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
}
