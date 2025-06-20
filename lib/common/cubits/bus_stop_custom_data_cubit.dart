// ignore_for_file: avoid_dynamic_calls Not needed

import 'package:aucorsa/common/models/bus_stop_custom_data.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

typedef BusStopCustomNameState = Map<int, BusStopCustomData>;

class BusStopCustomDataCubit extends HydratedCubit<BusStopCustomNameState> {
  BusStopCustomDataCubit() : super(BusStopCustomNameState());

  void set({required int stopId, String? name, int? icon}) => emit({
    ...state,
    stopId: BusStopCustomData(name: name, icon: icon),
  });

  BusStopCustomData? get(int stopId) => state[stopId];

  @override
  BusStopCustomNameState fromJson(Map<String, dynamic> json) =>
      json.map<int, BusStopCustomData>(
        (key, value) => MapEntry(
          int.parse(key),
          BusStopCustomData(
            name: value['name'] as String?,
            icon: value['icon'] as int?,
          ),
        ),
      );

  @override
  Map<String, dynamic> toJson(BusStopCustomNameState state) => state.map(
    (key, value) => MapEntry(
      key.toString(),
      {'name': value.name, 'icon': value.icon},
    ),
  );
}
