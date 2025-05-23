import 'package:aucorsa/common/utils/bus_line_utils.dart';
import 'package:aucorsa/common/utils/bus_stop_utils.dart';
import 'package:aucorsa/common/widgets/bus_line_tile.dart';
import 'package:aucorsa/stops/utils/map_path_bearing_utils.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

part 'bus_line_selector_state.dart';

class BusLineSelectorCubit extends Cubit<BusLineSelectorState> {
  static final initialState = BusLineSelectorState(
    stopCoordinates: BusLineUtils.lines
        .map((line) => line.stops)
        .expand((stop) => stop)
        .toSet()
        .map(BusStopUtils.resolveCoordinates)
        .whereType<BusStopCoordinates>()
        .toList(),
  );

  final BuildContext context;

  BusLineSelectorCubit(this.context) : super(initialState);

  void select(String lineId) {
    final linePath = BusLineUtils.getLinePath(lineId);
    final lineColor = BusLineTile.resolveLineBackgroundColor(
      context,
      BusLineUtils.getLine(lineId).color,
    );

    return emit(
      BusLineSelectorState(
        stopCoordinates: BusLineUtils.lines
            .where((line) => line.id == lineId)
            .map((line) => line.stops)
            .expand((stop) => stop)
            .toSet()
            .map(BusStopUtils.resolveCoordinates)
            .whereType<BusStopCoordinates>()
            .toList(),
        arrowMarkers: MapPathBearingUtils.resolveArrowMarkers(
          context: context,
          path: linePath,
          color: lineColor,
        ),
        linePath: linePath,
        lineColor: lineColor,
        lineId: lineId,
      ),
    );
  }

  void clear() => emit(initialState);
}
