import 'dart:ui';

class BusLine {
  final String id;
  final String name;
  final List<int> stops;
  final Color color;

  const BusLine({
    required this.id,
    required this.name,
    required this.stops,
    required this.color,
  });
}
