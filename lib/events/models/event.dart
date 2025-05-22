import 'package:aucorsa/events/models/event_id.dart';
import 'package:equatable/equatable.dart';

class Event extends Equatable {
  final EventId id;
  final DateTime startDate;
  final DateTime endDate;

  const Event({
    required this.id,
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [id, startDate, endDate];
}
