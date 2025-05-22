part of 'bus_line_selector_cubit.dart';

class BusLineSelectorState extends Equatable {
  final List<BusStopCoordinates> stopCoordinates;
  final List<Marker> arrowMarkers;
  final List<LatLng> linePath;
  final String? lineId;
  final Color? lineColor;

  const BusLineSelectorState({
    this.stopCoordinates = const [],
    this.arrowMarkers = const [],
    this.linePath = const [],
    this.lineId,
    this.lineColor,
  });

  @override
  List<Object?> get props => [
    stopCoordinates,
    arrowMarkers,
    linePath,
    lineId,
    lineColor,
  ];
}
