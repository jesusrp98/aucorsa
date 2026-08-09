import AppIntents
import AucorsaKit
import Foundation

/// Turns estimations into something Siri can say in one breath.
enum ArrivalsFormatter {
    /// Reading out every line at a busy stop is unusable by voice; the snippet
    /// view carries the full list.
    private static let spokenLineLimit = 3

    struct SpokenSelection {
        let estimations: [BusStopLineEstimation]
        let remainingCount: Int
    }

    static func spokenSelection(
        from estimations: [BusStopLineEstimation]
    ) -> SpokenSelection {
        let available = estimations.filter { $0.nextArrival != nil }
        let spoken = Array(available.prefix(spokenLineLimit))
        return SpokenSelection(
            estimations: spoken,
            remainingCount: available.count - spoken.count
        )
    }

    static func dialog(
        for estimations: [BusStopLineEstimation], stopName: String
    ) -> IntentDialog {
        let selection = spokenSelection(from: estimations)

        guard !selection.estimations.isEmpty else {
            return IntentDialog(
                LocalizedStringResource(
                    "No buses are expected at \(stopName) right now.",
                    table: "Intents"
                )
            )
        }

        let phrases = selection.estimations.compactMap(linePhrase(for:))

        let joined = phrases.joined(separator: ", ")
        let remaining = selection.remainingCount

        if remaining == 1 {
            return IntentDialog(
                LocalizedStringResource(
                    "At \(stopName): \(joined), and one more line.",
                    table: "Intents"
                )
            )
        }

        if remaining > 1 {
            return IntentDialog(
                LocalizedStringResource(
                    "At \(stopName): \(joined), and \(remaining) more lines.",
                    table: "Intents"
                )
            )
        }

        return IntentDialog(
            LocalizedStringResource("At \(stopName): \(joined).", table: "Intents")
        )
    }

    /// Dialog for a single line, used by `GetNextBusForLineIntent` where the
    /// answer should fit in one spoken sentence.
    static func dialog(
        for estimation: BusStopLineEstimation?, lineID: String, stopName: String
    ) -> IntentDialog {
        IntentDialog(
            lineDialogResource(
                for: estimation,
                lineID: lineID,
                stopName: stopName
            )
        )
    }

    /// Keeps every spoken word in one localized resource. In particular, the
    /// duration must not be formatted into a `String` first: Foundation would
    /// use the device locale, while App Intents resolves this resource using
    /// Siri's selected language.
    static func lineDialogResource(
        for estimation: BusStopLineEstimation?, lineID: String, stopName: String
    ) -> LocalizedStringResource {
        guard let estimation, let next = estimation.nextArrival else {
            return LocalizedStringResource(
                "Line \(lineID) is not due at \(stopName) right now.",
                table: "Intents"
            )
        }

        if estimation.arrivals.count > 1 {
            let following = estimation.arrivals[1]

            switch (next == 1, following == 1) {
            case (true, true):
                return LocalizedStringResource(
                    "Line \(lineID) arrives at \(stopName) in \(next) minute, then in \(following) minute.",
                    table: "Intents"
                )
            case (true, false):
                return LocalizedStringResource(
                    "Line \(lineID) arrives at \(stopName) in \(next) minute, then in \(following) minutes.",
                    table: "Intents"
                )
            case (false, true):
                return LocalizedStringResource(
                    "Line \(lineID) arrives at \(stopName) in \(next) minutes, then in \(following) minute.",
                    table: "Intents"
                )
            case (false, false):
                return LocalizedStringResource(
                    "Line \(lineID) arrives at \(stopName) in \(next) minutes, then in \(following) minutes.",
                    table: "Intents"
                )
            }
        }

        if next == 1 {
            return LocalizedStringResource(
                "Line \(lineID) arrives at \(stopName) in \(next) minute.",
                table: "Intents"
            )
        }

        return LocalizedStringResource(
            "Line \(lineID) arrives at \(stopName) in \(next) minutes.",
            table: "Intents"
        )
    }

    private static func linePhrase(
        for estimation: BusStopLineEstimation
    ) -> String? {
        guard let next = estimation.nextArrival else { return nil }

        return String(
            localized: "line \(estimation.lineID) in \(next) min",
            table: "Intents",
            comment: "One line's next arrival, joined by commas into a sentence"
        )
    }

    /// One arrival, formatted like the Flutter tile: "13 min", "1 h 11 min",
    /// and "Now" for a bus already at the stop.
    ///
    /// Matches `Duration.pretty(abbreviated: true, delimiter: ' ')` in Dart,
    /// which is what the app itself renders.
    static func arrivalLabel(minutes: Int) -> String {
        guard minutes > 0 else {
            return String(localized: "Now", table: "Intents")
        }

        let hours = minutes / 60
        let remainder = minutes % 60

        if hours == 0 {
            return String(localized: "\(minutes) min", table: "Intents")
        }

        if remainder == 0 {
            return String(localized: "\(hours) h", table: "Intents")
        }

        return String(localized: "\(hours) h \(remainder) min", table: "Intents")
    }
}
