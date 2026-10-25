import 'dart:async';

import 'package:aucorsa/common/cubits/bus_service_cubit.dart';
import 'package:aucorsa/common/cubits/bus_stop_state.dart';
import 'package:aucorsa/common/utils/aucorsa_state_status.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

class BusStopCubit extends Cubit<BusStopState> {
  final BusServiceCubit busServiceCubit;
  final int stopId;

  new({required this.busServiceCubit, required this.stopId})
    : super(BusStopState(stopId: stopId));

  Timer? _refreshTimer;
  Future<void>? _inFlight;

  void setAutoRefresh({required bool enabled}) {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    if (!enabled || isClosed) return;
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      unawaited(fetchEstimations(silent: true));
    });
  }

  Future<void> fetchEstimations({bool silent = false}) {
    if (isClosed) return Future.value();
    return _inFlight ??= _fetch(silent: silent).whenComplete(() {
      _inFlight = null;
    });
  }

  Future<void> _fetch({required bool silent}) async {
    if (!silent || state.fetchedAt == null) {
      emit(state.copyWith(status: AucorsaStateStatus.loading));
    }
    try {
      final estimations = await busServiceCubit.requestBusStopData(stopId);
      if (isClosed) return;
      emit(
        state.copyWith(
          estimations: estimations,
          status: AucorsaStateStatus.success,
          fetchedAt: DateTime.now(),
        ),
      );
    } on Exception {
      if (!isClosed) emit(state.copyWith(status: AucorsaStateStatus.error));
      // The existing bus service reports invalid API responses as StateError.
      // ignore: avoid_catching_errors
    } on StateError {
      if (!isClosed) emit(state.copyWith(status: AucorsaStateStatus.error));
    }
  }

  @override
  Future<void> close() {
    _refreshTimer?.cancel();
    return super.close();
  }
}
