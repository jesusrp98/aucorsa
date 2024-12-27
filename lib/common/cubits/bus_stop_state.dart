import 'package:aucorsa/common/models/bus_stop_line_estimation.dart';
import 'package:aucorsa/common/utils/aucorsa_state_status.dart';
import 'package:equatable/equatable.dart';

class BusStopState extends Equatable {
  final List<BusStopLineEstimation> estimations;
  final AucorsaStateStatus status;
  final int stopId;

  const BusStopState({
    required this.stopId,
    this.estimations = const [],
    this.status = AucorsaStateStatus.initial,
  });

  BusStopState copyWith({
    List<BusStopLineEstimation>? estimations,
    AucorsaStateStatus? status,
  }) =>
      BusStopState(
        estimations: estimations ?? this.estimations,
        status: status ?? this.status,
        stopId: stopId,
      );

  @override
  List<Object?> get props => [
        estimations,
        status,
        stopId,
      ];
}
