import 'dart:async';

import 'package:aucorsa/common/cubits/bus_stop_custom_data_cubit.dart';
import 'package:aucorsa/common/utils/app_group_bridge.dart';
import 'package:aucorsa/stops/cubits/favorite_stops_cubit.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'app_group_sync_state.dart';

/// Keeps the shared App Group mirror in step with the cubits that the iOS App
/// Intents layer reads from.
///
/// Subscribes to favourites and custom stop names, pushing a fresh payload
/// whenever either changes, plus once on construction so users upgrading with
/// existing favourites are covered.
///
/// Must be provided with `lazy: false`: nothing in the UI reads this cubit, so
/// a lazy provider would never construct it and mirroring would silently stop.
class AppGroupSyncCubit extends Cubit<AppGroupSyncState> {
  final FavoriteStopsCubit _favoriteStops;
  final BusStopCustomDataCubit _customData;
  final AppGroupSyncCallback _sync;

  late final StreamSubscription<List<int>> _favoritesSubscription;
  late final StreamSubscription<BusStopCustomNameState> _customDataSubscription;

  /// Guards against interleaved writes when several changes land in quick
  /// succession; a queued run picks up the latest state once the current one
  /// finishes.
  bool _isSyncing = false;
  bool _isResyncQueued = false;

  AppGroupSyncCubit({
    required FavoriteStopsCubit favoriteStops,
    required BusStopCustomDataCubit customData,
    AppGroupSyncCallback? sync,
  }) : _favoriteStops = favoriteStops,
       _customData = customData,
       _sync = sync ?? AppGroupBridge.sync,
       super(const AppGroupSyncState()) {
    // `stream` does not replay the current value, so this both seeds the mirror
    // and covers an upgrade with favourites already stored.
    unawaited(syncNow());

    _favoritesSubscription = favoriteStops.stream.listen(
      (_) => unawaited(syncNow()),
    );
    _customDataSubscription = customData.stream.listen(
      (_) => unawaited(syncNow()),
    );
  }

  /// Pushes the current state to the shared container.
  ///
  /// Called automatically on every change; exposed so a settings or diagnostics
  /// screen can retry after a failure.
  Future<void> syncNow() async {
    if (isClosed) return;

    if (_isSyncing) {
      _isResyncQueued = true;
      return;
    }

    _isSyncing = true;
    _emit(state.copyWith(status: AppGroupSyncStatus.syncing));

    final outcome = await _sync(
      favorites: _favoriteStops.state,
      customData: _customData.state,
    );

    _isSyncing = false;

    _emit(
      switch (outcome) {
        AppGroupSyncOutcome.synced => state.copyWith(
          status: AppGroupSyncStatus.synced,
          lastSyncedAt: DateTime.now(),
        ),
        AppGroupSyncOutcome.unsupported => state.copyWith(
          status: AppGroupSyncStatus.unsupported,
        ),
        AppGroupSyncOutcome.unavailable => state.copyWith(
          status: AppGroupSyncStatus.unavailable,
        ),
        AppGroupSyncOutcome.failed => state.copyWith(
          status: AppGroupSyncStatus.failed,
        ),
      },
    );

    if (_isResyncQueued && !isClosed) {
      _isResyncQueued = false;
      return syncNow();
    }
  }

  /// A sync can settle after the cubit is disposed, so every emit is guarded.
  void _emit(AppGroupSyncState next) {
    if (isClosed) return;

    emit(next);
  }

  @override
  Future<void> close() async {
    _isResyncQueued = false;
    await _favoritesSubscription.cancel();
    await _customDataSubscription.cancel();

    return super.close();
  }
}
