import 'dart:async';

import 'package:aucorsa/common/cubits/app_group_sync_cubit.dart';
import 'package:aucorsa/common/cubits/bus_stop_custom_data_cubit.dart';
import 'package:aucorsa/common/models/bus_stop_custom_data.dart';
import 'package:aucorsa/common/utils/app_group_bridge.dart';
import 'package:aucorsa/stops/cubits/favorite_stops_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

/// Records every payload the cubit pushes, and lets a test decide the outcome.
class _RecordingBridge {
  final List<({List<int> favorites, Map<int, BusStopCustomData> customData})>
  calls = [];

  AppGroupSyncOutcome outcome;

  /// Completes each call manually so a test can hold a sync in flight and
  /// observe what the cubit does with overlapping changes.
  final List<Completer<AppGroupSyncOutcome>> pending = [];
  bool manual;

  _RecordingBridge({
    this.outcome = AppGroupSyncOutcome.synced,
    this.manual = false,
  });

  Future<AppGroupSyncOutcome> sync({
    required List<int> favorites,
    required Map<int, BusStopCustomData> customData,
  }) {
    calls.add((favorites: List.of(favorites), customData: Map.of(customData)));

    if (!manual) return Future.value(outcome);

    final completer = Completer<AppGroupSyncOutcome>();
    pending.add(completer);
    return completer.future;
  }
}

/// The cubits under test are `HydratedCubit`s, so storage has to exist.
class _InMemoryStorage implements Storage {
  final Map<String, dynamic> _store = {};

  @override
  dynamic read(String key) => _store[key];

  @override
  Future<void> write(String key, dynamic value) async => _store[key] = value;

  @override
  Future<void> delete(String key) async => _store.remove(key);

  @override
  Future<void> clear() async => _store.clear();

  @override
  Future<void> close() async {}
}

void main() {
  late FavoriteStopsCubit favoriteStops;
  late BusStopCustomDataCubit customData;

  setUp(() {
    HydratedBloc.storage = _InMemoryStorage();
    favoriteStops = FavoriteStopsCubit();
    customData = BusStopCustomDataCubit();
  });

  tearDown(() async {
    await favoriteStops.close();
    await customData.close();
  });

  AppGroupSyncCubit build(_RecordingBridge bridge) => AppGroupSyncCubit(
    favoriteStops: favoriteStops,
    customData: customData,
    sync: bridge.sync,
  );

  test('syncs once on construction so upgrades are covered', () async {
    favoriteStops.add(105);
    final bridge = _RecordingBridge();

    final cubit = build(bridge);
    await pumpEventQueue();

    expect(bridge.calls, hasLength(1));
    expect(bridge.calls.single.favorites, [105]);
    expect(cubit.state.status, AppGroupSyncStatus.synced);
    expect(cubit.state.lastSyncedAt, isNotNull);

    await cubit.close();
  });

  test('pushes again when favourites change', () async {
    final bridge = _RecordingBridge();
    final cubit = build(bridge);
    await pumpEventQueue();

    favoriteStops.add(8);
    await pumpEventQueue();

    expect(bridge.calls, hasLength(2));
    expect(bridge.calls.last.favorites, [8]);

    await cubit.close();
  });

  test('pushes again when a custom stop name changes', () async {
    final bridge = _RecordingBridge();
    final cubit = build(bridge);
    await pumpEventQueue();

    customData.set(stopId: 105, name: 'Casa');
    await pumpEventQueue();

    expect(bridge.calls, hasLength(2));
    expect(bridge.calls.last.customData[105]?.name, 'Casa');

    await cubit.close();
  });

  test('reports an unprovisioned App Group as needing attention', () async {
    final bridge = _RecordingBridge(outcome: AppGroupSyncOutcome.unavailable);

    final cubit = build(bridge);
    await pumpEventQueue();

    expect(cubit.state.status, AppGroupSyncStatus.unavailable);
    expect(cubit.state.needsAttention, isTrue);
    expect(cubit.state.isMirrorAvailable, isFalse);
    expect(cubit.state.lastSyncedAt, isNull);

    await cubit.close();
  });

  test('does not flag non-iOS platforms as broken', () async {
    final bridge = _RecordingBridge(outcome: AppGroupSyncOutcome.unsupported);

    final cubit = build(bridge);
    await pumpEventQueue();

    expect(cubit.state.status, AppGroupSyncStatus.unsupported);
    expect(cubit.state.needsAttention, isFalse);

    await cubit.close();
  });

  test('coalesces changes that land while a sync is in flight', () async {
    final bridge = _RecordingBridge(manual: true);
    final cubit = build(bridge);
    await pumpEventQueue();

    // The construction sync is still open.
    expect(bridge.pending, hasLength(1));

    favoriteStops
      ..add(1)
      ..add(2);
    await pumpEventQueue();

    // Both changes queue behind the open call rather than racing it.
    expect(bridge.calls, hasLength(1));

    bridge.pending.first.complete(AppGroupSyncOutcome.synced);
    await pumpEventQueue();

    // Exactly one catch-up run, carrying the latest state.
    expect(bridge.calls, hasLength(2));
    expect(bridge.calls.last.favorites, [1, 2]);

    bridge.pending.last.complete(AppGroupSyncOutcome.synced);
    await pumpEventQueue();

    await cubit.close();
  });

  test('a sync settling after close does not emit', () async {
    final bridge = _RecordingBridge(manual: true);
    final cubit = build(bridge);
    await pumpEventQueue();

    await cubit.close();
    bridge.pending.first.complete(AppGroupSyncOutcome.synced);

    // Emitting after close would throw; reaching here without error is the
    // assertion.
    await pumpEventQueue();
  });

  test('a queued sync is discarded when the cubit closes', () async {
    final bridge = _RecordingBridge(manual: true);
    final cubit = build(bridge);
    await pumpEventQueue();

    favoriteStops.add(42);
    await pumpEventQueue();
    expect(bridge.calls, hasLength(1));

    await cubit.close();
    bridge.pending.first.complete(AppGroupSyncOutcome.synced);
    await pumpEventQueue();

    expect(bridge.calls, hasLength(1));
  });

  test('stops pushing once closed', () async {
    final bridge = _RecordingBridge();
    final cubit = build(bridge);
    await pumpEventQueue();

    await cubit.close();
    favoriteStops.add(42);
    await pumpEventQueue();

    expect(bridge.calls, hasLength(1));
  });
}
