import 'package:aucorsa/common/cubits/bus_stop_custom_data_cubit.dart';
import 'package:aucorsa/common/models/bus_stop_custom_data.dart';
import 'package:aucorsa/stops/cubits/bus_line_selector_cubit.dart';
import 'package:aucorsa/stops/map/aucorsa_map_icons.dart';
import 'package:aucorsa/stops/map/aucorsa_map_layer_cache.dart';
import 'package:aucorsa/stops/map/maplibre_layers.dart';
import 'package:aucorsa/stops/utils/map_path_bearing_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:maplibre/maplibre.dart' as ml;
import 'package:material_ui/material_ui.dart';

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
      customDataState: const {1: BusStopCustomData(name: 'Home')},
      devicePixelRatio: 3,
      stopColor: stopColor,
    );

    expect(identical(first, second), isTrue);
  });

  test('selecting, switching and clearing a line updates map sources', () {
    final cache = AucorsaMapLayerCache();
    final customData = BusStopCustomNameState();
    const allStops = BusLineSelectorState(
      stopCoordinates: [
        MapEntry(1, LatLng(37.89, -4.78)),
        MapEntry(2, LatLng(37.90, -4.79)),
      ],
    );
    const firstRoute = BusLineSelectorState(
      lineId: '1',
      lineColor: Colors.green,
      linePath: [LatLng(37.89, -4.78), LatLng(37.90, -4.79)],
      pathArrows: [MapPathArrow(point: LatLng(37.895, -4.785), angle: 0)],
      stopCoordinates: [MapEntry(1, LatLng(37.89, -4.78))],
    );
    // Keep the same color to ensure geometry changes alone trigger an update.
    const secondRoute = BusLineSelectorState(
      lineId: '2',
      lineColor: Colors.green,
      linePath: [LatLng(37.90, -4.79), LatLng(37.91, -4.80)],
      pathArrows: [MapPathArrow(point: LatLng(37.905, -4.795), angle: 1)],
      stopCoordinates: [MapEntry(2, LatLng(37.90, -4.79))],
    );

    List<ml.Layer> resolve(BusLineSelectorState lineState) => cache.resolve(
      lineState: lineState,
      customDataState: customData,
      devicePixelRatio: 3,
      stopColor: stopColor,
    );

    var previous = resolve(allStops);
    for (final nextState in [firstRoute, secondRoute, allStops]) {
      final next = resolve(nextState);
      for (var index = 0; index < 5; index++) {
        // MapLibre uses layer equality to decide whether to update its source.
        expect(next[index], isNot(previous[index]));
      }
      expect(next[0].list, hasLength(nextState.lineId == null ? 0 : 1));
      expect(next[1].list, hasLength(nextState.pathArrows.length));
      expect(next[2].list, hasLength(nextState.pathArrows.length));
      expect(
        next[3].list.map((feature) => feature.id),
        nextState.stopCoordinates.map((stop) => stop.key),
      );
      expect(
        next[4].list.map((feature) => feature.id),
        nextState.stopCoordinates.map((stop) => stop.key),
      );
      expect(identical(next, resolve(nextState)), isTrue);
      previous = next;
    }
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
