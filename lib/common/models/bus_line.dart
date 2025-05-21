import 'dart:ui';

import 'package:aucorsa/events/models/event_id.dart';

class BusLine {
  final String id;
  final String name;
  final List<int> stops;
  final Color color;
  final EventId? eventId;

  const BusLine({
    required this.id,
    required this.name,
    required this.stops,
    required this.color,
    this.eventId,
  });
}
