import 'dart:async';
import 'dart:convert';

import 'package:aucorsa/common/cubits/bus_stop_custom_data_cubit.dart';
import 'package:aucorsa/common/utils/bus_line_utils.dart';
import 'package:aucorsa/common/utils/bus_stop_search.dart';
import 'package:aucorsa/common/utils/bus_stop_utils.dart';
import 'package:aucorsa/stops/cubits/bus_line_selector_cubit.dart';
import 'package:aucorsa/stops/utils/asset_vector_tile_provider.dart';
import 'package:aucorsa/stops/utils/location_permission_utils.dart';
import 'package:aucorsa/stops/utils/map_marker_size.dart';
import 'package:aucorsa/stops/widgets/bus_stop_dialog.dart';
import 'package:aucorsa/stops/widgets/map_attribution_dialog.dart';
import 'package:compassx/compassx.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart' as map;

class AucorsaMap extends StatefulWidget {
  final EdgeInsets? margin;
  final bool zoomToLocationOnStart;

  const AucorsaMap({super.key, this.margin, this.zoomToLocationOnStart = true});

  @override
  State<AucorsaMap> createState() => _AucorsaMapState();
}

class _AucorsaMapState extends State<AucorsaMap> with TickerProviderStateMixin {
  static const hotelCordobaCenterLocation = LatLng(37.8916417, -4.7871324);
  // Reintroduced camera constraints at a later date
  // static const cameraConstraints = [
  //   LatLng(38.0287198393342, -4.647998576490011),
  //   LatLng(37.828534654889125, -4.942937979624105),
  // ];
  static const thresholdZoom = 15.5;
  static const markerSizeValues = {
    MapMarkerSize.dot: 8.0,
    MapMarkerSize.normal: 32.0,
  };
  static const baseMapColor = {
    Brightness.light: Color(0xFFEEEEEE),
    Brightness.dark: Color(0xFF333333),
  };

  late final animatedMapController = AnimatedMapController(vsync: this);

  late final alignPositionStreamController = StreamController<double?>();
  late final positionStream = const LocationMarkerDataStreamFactory()
      .fromGeolocatorPositionStream(
        stream: Geolocator.getPositionStream(
          locationSettings: const LocationSettings(distanceFilter: 5),
        ),
      );
  late final headingStream = CompassX.events.map(
    (event) => LocationMarkerHeading(
      heading: degToRadian(event.heading),
      accuracy: 0.4,
    ),
  );

  late final busStopCustomData = context.read<BusStopCustomDataCubit>();
  late AlignOnUpdate alignPositionOnUpdate = AlignOnUpdate.never;
  late MapMarkerSize markerSize;
  double rotation = 0;

  map.Theme? mapTileTheme;
  LatLng? initialCenter;

  @override
  void initState() {
    super.initState();

    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    if (!widget.zoomToLocationOnStart ||
        !await LocationPermissionUtils.resolve(context: context)) {
      return setState(() {
        alignPositionOnUpdate = AlignOnUpdate.never;
        markerSize = MapMarkerSize.dot;
        initialCenter = hotelCordobaCenterLocation;
      });
    }

    final position = await Geolocator.getCurrentPosition();
    return setState(() {
      alignPositionOnUpdate = AlignOnUpdate.always;
      markerSize = MapMarkerSize.normal;
      initialCenter = LatLng(position.latitude, position.longitude);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // No need to update if the theme hasn't changed
    if (mapTileTheme?.id == Theme.of(context).brightness.name) return;

    _updateVectorTileTheme();
  }

  @override
  void dispose() {
    alignPositionStreamController.close();

    super.dispose();
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
        if (initialCenter != null)
          FlutterMap(
            mapController: animatedMapController.mapController,
            options: MapOptions(
              backgroundColor: baseMapColor[Theme.of(context).brightness]!,
              onMapEvent: (event) => onRotationChanged(event.camera),
              onPositionChanged: onPositionChanged,
              initialCenter: initialCenter!,
              initialZoom: initialCenter == hotelCordobaCenterLocation
                  ? 13
                  : 18,
              minZoom: 11,
              maxZoom: 20,
            ),
            children: [
              if (mapTileTheme != null)
                VectorTileLayer(
                  theme: mapTileTheme!,
                  maximumZoom: 20,
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
                      rotate: true,
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
                                  resolveIcon(stop.key),
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
              CurrentLocationLayer(
                alignPositionStream: alignPositionStreamController.stream,
                alignPositionOnUpdate: alignPositionOnUpdate,
                headingStream: headingStream,
                positionStream: positionStream,
              ),
            ],
          ),
        Positioned(
          top: widget.margin?.top ?? padding.top + 16,
          right: 16,
          child: AnimatedOpacity(
            opacity: rotation != 0 ? 1.0 : 0.0,
            duration: Durations.medium2,
            curve: Curves.easeInOutCubic,
            child: FloatingActionButton.small(
              heroTag: null,
              shape: const CircleBorder(),
              backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
              foregroundColor: Theme.of(context).colorScheme.onSurface,
              onPressed: () => animatedMapController.animatedRotateTo(
                0,
                duration: Durations.medium2,
                curve: Curves.easeInOutCubic,
              ),
              child: Transform.rotate(
                angle: rotation - pi / 4,
                child: const Icon(Symbols.explore_rounded),
              ),
            ),
          ),
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
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.tertiaryContainer,
                foregroundColor: Theme.of(
                  context,
                ).colorScheme.onTertiaryContainer,
                heroTag: null,
                shape: const CircleBorder(),
                onPressed: onLocationButtonPressed,
                child: Icon(
                  Symbols.near_me_rounded,
                  fill: alignPositionOnUpdate == AlignOnUpdate.always ? 1 : 0,
                ),
              ),
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

  IconData resolveIcon(int stopId) {
    final data = busStopCustomData.get(stopId)?.icon;

    if (data != null) {
      return IconDataRounded(data);
    }

    return Symbols.directions_bus_rounded;
  }

  Future<void> onLocationButtonPressed() async {
    final hasLocationPermissions = await LocationPermissionUtils.resolve(
      context: context,
      askForPremission: true,
    );

    if (!hasLocationPermissions) return;

    alignPositionStreamController.add(18);

    return setState(() => alignPositionOnUpdate = AlignOnUpdate.always);
  }

  void onMarkerTap(BusStopCoordinates stop) {
    animatedMapController.animateTo(
      duration: Durations.medium2,
      curve: Curves.easeInOutCubic,
      dest: stop.value,
    );

    showBusStopDialog(context, stop.key);
  }

  void onPositionChanged(MapCamera camera, bool hasGesture) {
    if (hasGesture && alignPositionOnUpdate != AlignOnUpdate.never) {
      setState(() => alignPositionOnUpdate = AlignOnUpdate.never);
    }

    if (camera.zoom >= thresholdZoom && markerSize == MapMarkerSize.dot) {
      setState(() => markerSize = MapMarkerSize.normal);
    } else if (camera.zoom < thresholdZoom &&
        markerSize == MapMarkerSize.normal) {
      setState(() => markerSize = MapMarkerSize.dot);
    }
  }

  void onRotationChanged(MapCamera camera) {
    if (camera.rotationRad != rotation) {
      setState(() => rotation = camera.rotationRad);
    }
  }
}
