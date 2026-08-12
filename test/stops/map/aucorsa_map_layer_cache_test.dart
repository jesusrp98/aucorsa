import 'package:aucorsa/common/cubits/bus_stop_custom_data_cubit.dart';
import 'package:aucorsa/common/models/bus_stop_custom_data.dart';
import 'package:aucorsa/stops/cubits/bus_line_selector_cubit.dart';
import 'package:aucorsa/stops/map/aucorsa_map_icons.dart';
import 'package:aucorsa/stops/map/aucorsa_map_layer_cache.dart';
import 'package:aucorsa/stops/map/maplibre_layers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:maplibre/maplibre.dart' as ml;

void main() {
  const stopColor = Color(0xFFAAFFAA);

  BusLineSelectorState state() => const BusLineSelectorState(
    stopCoordinates: [MapEntry(1, LatLng(37.89, -4.78))],
  );

  test('retains the layer list while every input is identical', () {
    final cache = AucorsaMapLayerCache();
    final lineState = state();
    final customData = BusStopCustomNameState();

    final first = cache.resolve(
      lineState: lineState,
      customDataState: customData,
      devicePixelRatio: 3,
      stopColor: stopColor,
    );
    final second = cache.resolve(
      lineState: lineState,
      customDataState: customData,
      devicePixelRatio: 3,
      stopColor: stopColor,
    );

    expect(identical(first, second), isTrue);
    expect(first, hasLength(5 + AucorsaMapIcons.stopIcons.length));
  });

  test('rebuilds the layer list when a layer input changes', () {
    final cache = AucorsaMapLayerCache();
    final customData = BusStopCustomNameState();

    final first = cache.resolve(
      lineState: state(),
      customDataState: customData,
      devicePixelRatio: 3,
      stopColor: stopColor,
    );
    final second = cache.resolve(
      lineState: state(),
      customDataState: customData,
      devicePixelRatio: 2,
      stopColor: stopColor,
    );

    expect(identical(first, second), isFalse);
    expect(second, hasLength(first.length));
  });

  test('a stop-name-only change retains the layer list', () {
    final cache = AucorsaMapLayerCache();
    final lineState = state();

    final first = cache.resolve(
      lineState: lineState,
      customDataState: BusStopCustomNameState(),
      devicePixelRatio: 3,
      stopColor: stopColor,
    );
    final second = cache.resolve(
      lineState: lineState,
      customDataState: const {
        1: BusStopCustomData(name: 'Home'),
      },
      devicePixelRatio: 3,
      stopColor: stopColor,
    );

    expect(identical(first, second), isTrue);
  });

  test('stable layer equality ignores its GeoJSON feature list', () {
    const first = StableCircleLayer(
      points: <ml.Feature<ml.Point>>[],
      radius: 4,
      color: stopColor,
    );
    const second = StableCircleLayer(
      points: <ml.Feature<ml.Point>>[],
      radius: 4,
      color: stopColor,
    );

    expect(first, second);
  });

  test('marker visibility changes through zoom opacity', () {
    const layer = StableMarkerLayer(
      points: <ml.Feature<ml.Point>>[],
      iconImage: 'stop',
      iconSize: 1,
      visibleFromZoom: 15.5,
    );

    expect(layer.minZoom, 0);
    expect(layer.getPaint()['icon-opacity'], [
      'step',
      ['zoom'],
      0.0,
      15.5,
      1.0,
    ]);
  });
}
