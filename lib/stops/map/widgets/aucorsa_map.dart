import 'dart:async';
import 'dart:math';

import 'package:aucorsa/common/cubits/bus_stop_custom_data_cubit.dart';
import 'package:aucorsa/common/utils/bus_stop_utils.dart';
import 'package:aucorsa/stops/cubits/bus_line_selector_cubit.dart';
import 'package:aucorsa/stops/map/aucorsa_map_config.dart';
import 'package:aucorsa/stops/map/aucorsa_map_icons.dart';
import 'package:aucorsa/stops/map/aucorsa_map_layer_cache.dart';
import 'package:aucorsa/stops/map/offline/offline_map_installer.dart';
import 'package:aucorsa/stops/map/offline/offline_map_style.dart';
import 'package:aucorsa/stops/map/widgets/aucorsa_map_controls.dart';
import 'package:aucorsa/stops/map/widgets/aucorsa_map_error.dart';
import 'package:aucorsa/stops/utils/location_permission_utils.dart';
import 'package:aucorsa/stops/widgets/bus_stop_dialog.dart';
import 'package:aucorsa/stops/widgets/location_outside_map_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre/maplibre.dart' as ml;

class AucorsaMap extends StatefulWidget {
  final EdgeInsets? margin;
  final bool zoomToLocationOnStart;

  const AucorsaMap({super.key, this.margin, this.zoomToLocationOnStart = true});

  @override
  State<AucorsaMap> createState() => _AucorsaMapState();
}

class _AucorsaMapState extends State<AucorsaMap> {
  final rotation = ValueNotifier<double>(0);
  final followLocation = ValueNotifier<bool>(false);
  final layerCache = AucorsaMapLayerCache();

  ml.MapController? mapController;
  Brightness? mapStyleBrightness;
  PreparedOfflineMap? preparedMap;
  Object? mapLoadError;
  ml.Geographic? initialCenter;
  Position? initialPosition;
  bool initialLocationResolved = false;
  bool locationPermissionGranted = false;
  bool mapBoundsReady = false;
  PreparedOfflineMap? cachedWidgetMapData;
  ml.Geographic? cachedWidgetInitialCenter;
  List<ml.Layer>? cachedWidgetLayers;
  Brightness? cachedWidgetBrightness;
  bool? cachedWidgetBoundsReady;
  ml.MapLibreMap? cachedMapWidget;

  @override
  void initState() {
    super.initState();
    unawaited(_initializeLocation());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final brightness = Theme.of(context).brightness;
    if (mapStyleBrightness == brightness) return;

    mapStyleBrightness = brightness;
    unawaited(_updateMapStyle(brightness));
  }

  @override
  void dispose() {
    rotation.dispose();
    followLocation.dispose();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    try {
      if (widget.zoomToLocationOnStart &&
          await LocationPermissionUtils.resolve(context: context)) {
        locationPermissionGranted = true;
        initialPosition =
            await Geolocator.getLastKnownPosition() ??
            await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                timeLimit: Duration(seconds: 5),
              ),
            );
      }
    } on Exception {
      // A slow or unavailable GPS fix must not hold up the offline map.
    }

    if (!mounted) return;

    initialLocationResolved = true;
    _resolveInitialCenter();
  }

  void _resolveInitialCenter() {
    final mapData = preparedMap;
    if (!mounted ||
        initialCenter != null ||
        !initialLocationResolved ||
        mapData == null) {
      return;
    }

    final position = initialPosition;
    final isInsideMap = position != null && _contains(position);
    followLocation.value = isInsideMap;
    setState(() {
      initialCenter = isInsideMap
          ? ml.Geographic(lon: position.longitude, lat: position.latitude)
          : AucorsaMapConfig.defaultCenter;
    });
  }

  Future<void> _updateMapStyle(Brightness brightness) async {
    try {
      final mapData = await OfflineMapStyle.prepare(brightness);
      if (!mounted || mapStyleBrightness != brightness) return;

      setState(() {
        mapLoadError = null;
        preparedMap = mapData;
      });
      _resolveInitialCenter();
      mapController?.setStyle(mapData.styleJson);
    } on Object catch (error) {
      if (!mounted || mapStyleBrightness != brightness) return;

      setState(() => mapLoadError = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busLineSelectorState = context.watch<BusLineSelectorCubit>().state;
    final customDataState = context.watch<BusStopCustomDataCubit>().state;
    final brightness = Theme.of(context).brightness;
    final padding = MediaQuery.paddingOf(context);

    return Stack(
      children: [
        Positioned.fill(
          child: _buildMap(
            busLineSelectorState,
            customDataState,
            brightness,
          ),
        ),
        if (preparedMap != null) ...[
          Positioned(
            top: widget.margin?.top ?? padding.top + 16,
            right: max(padding.right, 16),
            child: AucorsaMapCompassButton(
              rotation: rotation,
              onPressed: _resetBearing,
            ),
          ),
          Positioned(
            top: padding.top + 24 + kToolbarHeight,
            right: max(padding.right, 16),
            child: AucorsaMapLocationButton(
              followLocation: followLocation,
              onPressed: onLocationButtonPressed,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMap(
    BusLineSelectorState busLineSelectorState,
    BusStopCustomNameState customDataState,
    Brightness brightness,
  ) {
    final mapData = preparedMap;
    if (mapData == null || initialCenter == null) {
      return ColoredBox(
        color: AucorsaMapConfig.baseMapColor[brightness]!,
        child: switch (mapLoadError) {
          null => null,
          OfflineMapAssetsUnavailable() => null,
          _ => AucorsaMapError(onRetry: _retryMapStyle),
        },
      );
    }

    final center = initialCenter!;
    final layers = layerCache.resolve(
      lineState: busLineSelectorState,
      customDataState: customDataState,
      devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
      stopColor: Theme.of(context).colorScheme.primaryFixed,
    );
    if (identical(cachedWidgetMapData, mapData) &&
        cachedWidgetInitialCenter == center &&
        identical(cachedWidgetLayers, layers) &&
        cachedWidgetBrightness == brightness &&
        cachedWidgetBoundsReady == mapBoundsReady) {
      return cachedMapWidget!;
    }

    final mapWidget = ml.MapLibreMap(
      options: ml.MapOptions(
        initStyle: mapData.styleJson,
        initCenter: center,
        initZoom: center == AucorsaMapConfig.defaultCenter
            ? AucorsaMapConfig.defaultCenterZoom
            : AucorsaMapConfig.userLocationZoom,
        minZoom: mapData.minimumZoom,
        maxZoom: AucorsaMapConfig.maximumZoom,
        maxBounds: mapBoundsReady ? mapData.bounds : null,
        androidForegroundLoadColor: AucorsaMapConfig.baseMapColor[brightness]!,
      ),
      onMapCreated: _onMapCreated,
      onStyleLoaded: _onStyleLoaded,
      onEvent: _onMapEvent,
      layers: layers,
    );
    cachedWidgetMapData = mapData;
    cachedWidgetInitialCenter = center;
    cachedWidgetLayers = layers;
    cachedWidgetBrightness = brightness;
    cachedWidgetBoundsReady = mapBoundsReady;
    cachedMapWidget = mapWidget;
    return mapWidget;
  }

  void _onMapCreated(ml.MapController controller) {
    mapController = controller;
    _showCurrentLocation();
    // Applying maxBounds during native map creation can clamp the initial
    // camera before MapLibre has finished restoring it. Enable the constraint
    // on the following frame, once the initial camera is established.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || mapController != controller || mapBoundsReady) return;

      setState(() => mapBoundsReady = true);
    });
  }

  void _onStyleLoaded(ml.StyleController style) {
    _showCurrentLocation();
    unawaited(
      AucorsaMapIcons.install(
        style,
        stopIconColor: Theme.of(context).colorScheme.onPrimaryFixed,
        devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
      ),
    );
  }

  void _showCurrentLocation() {
    if (!locationPermissionGranted || mapController == null) return;

    unawaited(_enableCurrentLocation());
  }

  Future<void> _enableCurrentLocation() async {
    try {
      await mapController?.enableLocation(
        bearingRenderMode: ml.BearingRenderMode.compass,
      );
      if (followLocation.value) {
        await mapController?.trackLocation(
          trackBearing: ml.BearingTrackMode.none,
        );
      }
    } on Exception {
      // The map remains usable if native location rendering is unavailable.
    }
  }

  void _onMapEvent(ml.MapEvent event) {
    if (event case ml.MapEventStartMoveCamera(
      reason: ml.CameraChangeReason.apiGesture,
    )) {
      if (followLocation.value) {
        followLocation.value = false;
        unawaited(
          mapController?.trackLocation(
            trackLocation: false,
            trackBearing: ml.BearingTrackMode.none,
          ),
        );
      }
      return;
    }

    if (event case ml.MapEventClick(:final screenPoint)) {
      _handleMapClick(screenPoint);
      return;
    }

    if (event case ml.MapEventMoveCamera(:final camera)) {
      final nextRotation = camera.bearing * pi / 180;
      if (nextRotation != rotation.value) rotation.value = nextRotation;
    }
  }

  void _handleMapClick(Offset screenPoint) {
    final controller = mapController;
    if (controller == null) return;

    final features = controller.featuresAtPoint(screenPoint);
    for (final feature in features) {
      final value = feature.properties[AucorsaMapConfig.stopIdProperty];
      final stopId = switch (value) {
        final int value => value,
        final num value => value.toInt(),
        final String value => int.tryParse(value),
        _ => null,
      };
      if (stopId == null) continue;

      for (final stop
          in context.read<BusLineSelectorCubit>().state.stopCoordinates) {
        if (stop.key == stopId) {
          onMarkerTap(stop);
          return;
        }
      }
    }
  }

  void _resetBearing() {
    unawaited(
      mapController?.animateCamera(
        bearing: 0,
        nativeDuration: Durations.medium2,
      ),
    );
  }

  void _retryMapStyle() {
    final brightness = mapStyleBrightness ?? Theme.of(context).brightness;
    setState(() => mapLoadError = null);
    unawaited(_updateMapStyle(brightness));
  }

  Future<void> onLocationButtonPressed() async {
    final hasLocationPermissions = await LocationPermissionUtils.resolve(
      context: context,
      askForPremission: true,
    );
    if (!hasLocationPermissions || !mounted) return;

    final position = await Geolocator.getCurrentPosition();
    if (!mounted) return;

    final isInsideMap = _contains(position);
    followLocation.value = isInsideMap;
    locationPermissionGranted = true;

    if (!isInsideMap) {
      try {
        await mapController?.trackLocation(
          trackLocation: false,
          trackBearing: ml.BearingTrackMode.none,
        );
      } on Exception {
        // The dialog is independent of native location tracking.
      }

      if (mounted) await showLocationOutsideMapDialog(context);
      return;
    }

    await _enableCurrentLocation();
    await mapController?.animateCamera(
      center: ml.Geographic(
        lon: position.longitude,
        lat: position.latitude,
      ),
      zoom: AucorsaMapConfig.userLocationZoom,
      nativeDuration: Durations.medium2,
    );
  }

  void onMarkerTap(BusStopCoordinates stop) {
    unawaited(
      mapController?.animateCamera(
        center: ml.Geographic(
          lon: stop.value.longitude,
          lat: stop.value.latitude,
        ),
        nativeDuration: Durations.medium2,
      ),
    );

    unawaited(showBusStopDialog(context, stop.key));
  }

  bool _contains(Position position) {
    final bounds = preparedMap?.bounds;
    return bounds != null &&
        AucorsaMapConfig.contains(
          bounds,
          longitude: position.longitude,
          latitude: position.latitude,
        );
  }
}
