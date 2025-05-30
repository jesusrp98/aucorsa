import 'dart:convert';

import 'package:aucorsa/common/utils/bus_line_utils.dart';
import 'package:aucorsa/common/utils/bus_stop_search.dart';
import 'package:aucorsa/common/utils/bus_stop_utils.dart';
import 'package:aucorsa/stops/cubits/bus_line_selector_cubit.dart';
import 'package:aucorsa/stops/utils/asset_vector_tile_provider.dart';
import 'package:aucorsa/stops/utils/map_marker_size.dart';
import 'package:aucorsa/stops/widgets/bus_stop_dialog.dart';
import 'package:aucorsa/stops/widgets/map_attribution_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart' as map;

class AucorsaMap extends StatefulWidget {
  const AucorsaMap({super.key});

  @override
  State<AucorsaMap> createState() => _AucorsaMapState();
}

class _AucorsaMapState extends State<AucorsaMap> with TickerProviderStateMixin {
  static const hotelCordobaCenterLocation = LatLng(37.8916417, -4.7871324);
  static const cameraConstraints = [
    LatLng(38.0287198393342, -4.647998576490011),
    LatLng(37.828534654889125, -4.942937979624105),
  ];
  static const thresholdZoom = 15.5;
  static const markerSizeValues = {
    MapMarkerSize.dot: 8.0,
    MapMarkerSize.normal: 32.0,
  };
  static final baseMapColor = {
    Brightness.light: const Color(0xFFEEEEEE),
    Brightness.dark: const Color(0xFF333333),
  };

  late MapMarkerSize markerSize = MapMarkerSize.dot;
  late final animatedMapController = AnimatedMapController(vsync: this);
  map.Theme? mapTileTheme;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // No need to update if the theme hasn't changed
    if (mapTileTheme?.id == Theme.of(context).brightness.name) return;

    _updateVectorTileTheme();
  }

  Future<void> _updateVectorTileTheme() async {
    final jsonString = await rootBundle.loadString(
      'assets/vector-map-styles/${Theme.of(context).brightness.name}.json',
    );

    final theme = map.ThemeReader().read(
      json.decode(jsonString) as Map<String, dynamic>,
    );

    if (!mounted) return;

    return setState(() => mapTileTheme = theme);
  }

  @override
  Widget build(BuildContext context) {
    final busLineSelectorState = context.watch<BusLineSelectorCubit>().state;
    final padding = MediaQuery.paddingOf(context);

    return Stack(
      children: [
        FlutterMap(
          mapController: animatedMapController.mapController,
          options: MapOptions(
            backgroundColor: baseMapColor[Theme.of(context).brightness]!,
            cameraConstraint: CameraConstraint.containCenter(
              bounds: LatLngBounds.fromPoints(cameraConstraints),
            ),
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
            initialCenter: hotelCordobaCenterLocation,
            onPositionChanged: onPositionChanged,
            maxZoom: 20,
            minZoom: 11,
          ),
          children: [
            if (mapTileTheme != null)
              VectorTileLayer(
                theme: mapTileTheme!,
                layerMode: VectorTileLayerMode.vector,
                tileProviders: TileProviders({
                  'openmaptiles': AssetVectorTileProvider(),
                }),
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
                              onTap: () => onMarkerTap(stop),
                              child: Icon(
                                Symbols.directions_bus_rounded,
                                fill: 1,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryFixed,
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

  void onMarkerTap(BusStopCoordinates stop) {
    animatedMapController.animateTo(
      duration: Durations.medium2,
      curve: Curves.easeInOutCubic,
      dest: stop.value,
    );

    showBusStopDialog(context, stop.key);
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
