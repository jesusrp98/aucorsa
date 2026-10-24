import 'package:maplibre/maplibre.dart' as ml;
import 'package:material_ui/material_ui.dart';

/// Layers whose equality includes both source data and style configuration.
///
/// MapLibre uses layer equality to decide whether to update the GeoJSON source.
/// The layer cache retains these instances while their inputs are unchanged.
final class StablePolylineLayer extends ml.Layer<ml.Feature<ml.LineString>> {
  final String colorProperty;
  final int width;

  const new({
    required List<ml.Feature<ml.LineString>> polylines,
    required this.colorProperty,
    required this.width,
  }) : super(list: polylines);

  @override
  ml.StyleLayer createStyleLayer(int index) => ml.LineStyleLayer(
    id: getLayerId(index),
    sourceId: getSourceId(index),
    paint: getPaint(),
    layout: getLayout(),
    minZoom: minZoom,
    maxZoom: maxZoom,
  );

  @override
  Map<String, Object> getPaint() => {
    'line-color': ['get', colorProperty],
    'line-opacity': 1.0,
    'line-width': width,
    'line-gap-width': 0,
  };

  @override
  Map<String, Object> getLayout() => const {};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StablePolylineLayer &&
          super == other &&
          colorProperty == other.colorProperty &&
          width == other.width;

  @override
  int get hashCode => Object.hash(super.hashCode, colorProperty, width);
}

final class StableCircleLayer extends ml.Layer<ml.Feature<ml.Point>> {
  final int radius;
  final Color? color;
  final String? colorProperty;

  const new({
    required List<ml.Feature<ml.Point>> points,
    required this.radius,
    this.color,
    this.colorProperty,
    super.minZoom,
    super.maxZoom,
  }) : assert(
         (color == null) != (colorProperty == null),
         'Provide either color or colorProperty',
       ),
       super(list: points);

  @override
  ml.StyleLayer createStyleLayer(int index) => ml.CircleStyleLayer(
    id: getLayerId(index),
    sourceId: getSourceId(index),
    paint: getPaint(),
    layout: getLayout(),
    minZoom: minZoom,
    maxZoom: maxZoom,
  );

  @override
  Map<String, Object> getPaint() => {
    'circle-radius': radius,
    'circle-color': colorProperty == null
        ? color!.toHexString()
        : ['get', colorProperty!],
    'circle-opacity': color?.a ?? 1.0,
    'circle-blur': 0.0,
    'circle-stroke-width': 0,
  };

  @override
  Map<String, Object> getLayout() => const {};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StableCircleLayer &&
          super == other &&
          radius == other.radius &&
          color == other.color &&
          colorProperty == other.colorProperty;

  @override
  int get hashCode => Object.hash(super.hashCode, radius, color, colorProperty);
}

final class StableMarkerLayer extends ml.Layer<ml.Feature<ml.Point>> {
  final String iconImage;
  final double iconSize;
  final String? bearingProperty;
  final double? visibleFromZoom;

  const new({
    required List<ml.Feature<ml.Point>> points,
    required this.iconImage,
    required this.iconSize,
    this.bearingProperty,
    this.visibleFromZoom,
  }) : super(list: points);

  @override
  ml.StyleLayer createStyleLayer(int index) => ml.SymbolStyleLayer(
    id: getLayerId(index),
    sourceId: getSourceId(index),
    paint: getPaint(),
    layout: getLayout(),
    minZoom: minZoom,
    maxZoom: maxZoom,
  );

  @override
  Map<String, Object> getPaint() => {
    'icon-opacity': visibleFromZoom == null
        ? 1.0
        : [
            'step',
            ['zoom'],
            0.0,
            visibleFromZoom!,
            1.0,
          ],
  };

  @override
  Map<String, Object> getLayout() => {
    'icon-image': iconImage,
    'icon-size': iconSize,
    if (bearingProperty case final property?) ...{
      'icon-rotate': ['get', property],
      'icon-rotation-alignment': 'map',
    },
    'icon-allow-overlap': true,
    'icon-ignore-placement': true,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StableMarkerLayer &&
          super == other &&
          iconImage == other.iconImage &&
          iconSize == other.iconSize &&
          bearingProperty == other.bearingProperty &&
          visibleFromZoom == other.visibleFromZoom;

  @override
  int get hashCode => Object.hash(
    super.hashCode,
    iconImage,
    iconSize,
    bearingProperty,
    visibleFromZoom,
  );
}
