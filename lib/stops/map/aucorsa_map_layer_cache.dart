import 'dart:math';

import 'package:aucorsa/common/cubits/bus_stop_custom_data_cubit.dart';
import 'package:aucorsa/stops/cubits/bus_line_selector_cubit.dart';
import 'package:aucorsa/stops/map/aucorsa_map_config.dart';
import 'package:aucorsa/stops/map/aucorsa_map_icons.dart';
import 'package:aucorsa/stops/map/maplibre_layers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:maplibre/maplibre.dart' as ml;

/// Retains layer and feature-list identity until a real layer input changes.
///
/// Stable layer equality prevents unnecessary native style-layer replacement.
/// The caller also memoizes the `MapLibreMap` widget using this list's
/// identity;
/// that is what prevents an unchanged list from reaching `didUpdateWidget` and
/// being serialized to GeoJSON again.
final class AucorsaMapLayerCache {
  BusLineSelectorState? _lineState;
  List<int>? _stopIconCodes;
  double? _devicePixelRatio;
  Color? _stopColor;
  late List<ml.Layer> _layers;

  List<ml.Layer> resolve({
    required BusLineSelectorState lineState,
    required BusStopCustomNameState customDataState,
    required double devicePixelRatio,
    required Color stopColor,
  }) {
    final stopIconCodes = [
      for (final stop in lineState.stopCoordinates)
        AucorsaMapIcons.resolveStopIcon(
          stop.key,
          customDataState,
        ).codePoint,
    ];
    if (identical(_lineState, lineState) &&
        listEquals(_stopIconCodes, stopIconCodes) &&
        _devicePixelRatio == devicePixelRatio &&
        _stopColor == stopColor) {
      return _layers;
    }

    final routeLineFeatures = _buildRouteLineFeatures(lineState);
    final routeArrowFeatures = _buildRouteArrowFeatures(lineState);
    final stopFeatures = _buildStopFeatures(lineState);

    final layers = <ml.Layer>[
      StablePolylineLayer(
        polylines: routeLineFeatures,
        colorProperty: AucorsaMapConfig.routeColorProperty,
        width: 4,
      ),
      StableCircleLayer(
        points: routeArrowFeatures,
        radius: AucorsaMapConfig.arrowMarkerRadius,
        colorProperty: AucorsaMapConfig.routeColorProperty,
      ),
      StableMarkerLayer(
        points: routeArrowFeatures,
        iconImage: AucorsaMapIcons.routeArrowId,
        iconSize: 1 / devicePixelRatio,
        bearingProperty: AucorsaMapConfig.routeArrowBearingProperty,
      ),
      StableCircleLayer(
        points: stopFeatures.dots,
        radius: AucorsaMapConfig.dotMarkerRadius,
        color: stopColor,
        maxZoom: AucorsaMapConfig.stopDetailZoom,
      ),
      StableCircleLayer(
        points: stopFeatures.interactive,
        radius: AucorsaMapConfig.stopMarkerRadius,
        color: stopColor,
        minZoom: AucorsaMapConfig.stopDetailZoom,
      ),
      ..._buildStopIconLayers(
        lineState,
        stopFeatures.interactive,
        customDataState,
        devicePixelRatio,
      ),
    ];

    _lineState = lineState;
    _stopIconCodes = List.unmodifiable(stopIconCodes);
    _devicePixelRatio = devicePixelRatio;
    _stopColor = stopColor;
    return _layers = List.unmodifiable(layers);
  }

  List<ml.Feature<ml.LineString>> _buildRouteLineFeatures(
    BusLineSelectorState state,
  ) {
    if (state.linePath.length < 2 || state.lineColor == null) return const [];

    return List.unmodifiable([
      ml.Feature(
        properties: {
          AucorsaMapConfig.routeColorProperty: state.lineColor!.toHexString(),
        },
        geometry: ml.LineString.from(
          state.linePath.map(
            (point) => ml.Geographic(
              lon: point.longitude,
              lat: point.latitude,
            ),
          ),
        ),
      ),
    ]);
  }

  List<ml.Feature<ml.Point>> _buildRouteArrowFeatures(
    BusLineSelectorState state,
  ) {
    if (state.pathArrows.isEmpty || state.lineColor == null) return const [];

    return List.unmodifiable([
      for (final arrow in state.pathArrows)
        ml.Feature(
          properties: {
            AucorsaMapConfig.routeArrowBearingProperty: arrow.angle * 180 / pi,
            AucorsaMapConfig.routeColorProperty: state.lineColor!.toHexString(),
          },
          geometry: ml.Point(
            ml.Geographic(
              lon: arrow.point.longitude,
              lat: arrow.point.latitude,
            ),
          ),
        ),
    ]);
  }

  ({
    List<ml.Feature<ml.Point>> dots,
    List<ml.Feature<ml.Point>> interactive,
  })
  _buildStopFeatures(BusLineSelectorState state) {
    final dots = <ml.Feature<ml.Point>>[];
    final interactive = <ml.Feature<ml.Point>>[];
    for (final stop in state.stopCoordinates) {
      final geometry = ml.Point(
        ml.Geographic(
          lon: stop.value.longitude,
          lat: stop.value.latitude,
        ),
      );
      dots.add(ml.Feature(id: stop.key, geometry: geometry));
      interactive.add(
        ml.Feature(
          id: stop.key,
          properties: {AucorsaMapConfig.stopIdProperty: stop.key},
          geometry: geometry,
        ),
      );
    }

    return (
      dots: List.unmodifiable(dots),
      interactive: List.unmodifiable(interactive),
    );
  }

  List<ml.Layer> _buildStopIconLayers(
    BusLineSelectorState state,
    List<ml.Feature<ml.Point>> stopFeatures,
    BusStopCustomNameState customDataState,
    double devicePixelRatio,
  ) {
    final stopsByIcon = {
      for (final icon in AucorsaMapIcons.stopIcons)
        icon: <ml.Feature<ml.Point>>[],
    };
    for (var index = 0; index < state.stopCoordinates.length; index++) {
      final stop = state.stopCoordinates[index];
      final icon = AucorsaMapIcons.resolveStopIcon(
        stop.key,
        customDataState,
      );
      stopsByIcon[icon]!.add(stopFeatures[index]);
    }

    return [
      for (final icon in AucorsaMapIcons.stopIcons)
        StableMarkerLayer(
          points: List.unmodifiable(stopsByIcon[icon]!),
          iconImage: AucorsaMapIcons.stopIconId(icon),
          iconSize: 1 / devicePixelRatio,
          // A layer minZoom would trigger MapLibre's symbol-placement fade.
          visibleFromZoom: AucorsaMapConfig.stopDetailZoom,
        ),
    ];
  }
}
