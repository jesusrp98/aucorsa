part of 'bus_line_selector_cubit.dart';

class BusLineSelectorState extends Equatable {
  final List<BusStopCoordinates> stopCoordinates;
  final List<MapPathArrow> pathArrows;
  final List<LatLng> linePath;
  final String? lineId;
  final Color? lineColor;

  const BusLineSelectorState({
    this.stopCoordinates = const [],
    this.pathArrows = const [],
    this.linePath = const [],
    this.lineId,
    this.lineColor,
  });

  @override
  List<Object?> get props => [
    stopCoordinates,
    pathArrows,
    linePath,
    lineId,
    lineColor,
  ];
}
