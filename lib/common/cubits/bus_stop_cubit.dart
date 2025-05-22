import 'package:aucorsa/common/cubits/bus_service_cubit.dart';
import 'package:aucorsa/common/cubits/bus_stop_state.dart';
import 'package:aucorsa/common/utils/aucorsa_state_status.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

class BusStopCubit extends Cubit<BusStopState> {
  final BusServiceCubit busServiceCubit;
  final int stopId;

  BusStopCubit({required this.busServiceCubit, required this.stopId})
    : super(BusStopState(stopId: stopId));

  Future<void> fetchEstimations() async {
    emit(state.copyWith(status: AucorsaStateStatus.loading));

    return busServiceCubit
        .requestBusStopData(state.stopId)
        .then(
          (estimations) => emit(
            state.copyWith(
              estimations: estimations,
              status: AucorsaStateStatus.success,
            ),
          ),
        )
        .catchError((_) {
          if (isClosed) return;

          return emit(state.copyWith(status: AucorsaStateStatus.error));
        });
  }
}
