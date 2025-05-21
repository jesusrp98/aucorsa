import 'package:aucorsa/events/models/event.dart';
import 'package:aucorsa/events/models/event_id.dart';

class EventsCalendar {
  static final now = DateTime.now();

  static final allEvents = [
    Event(
      id: EventId.feria,
      startDate: DateTime(now.year, 5, 15),
      endDate: DateTime(now.year, 6),
    ),
  ];

  static final currentEvents = allEvents
      .where(
        (event) => event.startDate.isBefore(now) && event.endDate.isAfter(now),
      )
      .toList();

  const EventsCalendar();
}
