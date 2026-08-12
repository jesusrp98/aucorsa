import Foundation

/// Identifier for a calendar event that gates a set of lines.
///
/// Mirrors `lib/events/models/event_id.dart`. Decoded leniently: the generator
/// writes whatever AUCORSA declares, and an unknown value must not fail the
/// whole catalog load.
public enum TransitEventID: String, Codable, Hashable, Sendable, CaseIterable {
    case feria
}

/// Date window during which an event's lines are in service.
public struct TransitEvent: Hashable, Sendable {
    public let id: TransitEventID
    public let startDate: DateComponents
    public let endDate: DateComponents
}

/// Port of `lib/events/models/events_calendar.dart`.
///
/// The Dart version pins the window to the *current* year via `DateTime.now()`;
/// this recomputes against whatever date it is asked about, so the intent layer
/// stays testable.
public enum TransitEventsCalendar {
    static let allEvents: [TransitEvent] = [
        TransitEvent(
            id: .feria,
            startDate: DateComponents(month: 5, day: 15),
            endDate: DateComponents(month: 6, day: 1)
        )
    ]

    /// Events active on `date`, resolved against that date's calendar year.
    public static func currentEvents(
        on date: Date = Date(),
        calendar: Calendar = .current
    ) -> Set<TransitEventID> {
        let year = calendar.component(.year, from: date)

        return Set(
            allEvents.compactMap { event in
                guard
                    let start = calendar.date(
                        from: DateComponents(
                            year: year,
                            month: event.startDate.month,
                            day: event.startDate.day
                        )
                    ),
                    let end = calendar.date(
                        from: DateComponents(
                            year: year,
                            month: event.endDate.month,
                            day: event.endDate.day
                        )
                    )
                else { return nil }

                // Matches the Dart predicate: strictly after start, strictly
                // before end.
                return start < date && date < end ? event.id : nil
            }
        )
    }
}
