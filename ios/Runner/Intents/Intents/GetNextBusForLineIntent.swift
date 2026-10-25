#if LIVE_ACTIVITIES
import ActivityKit
#endif
import AppIntents
import AucorsaKit
import Foundation

/// "When does the 3 come by my stop?"
///
/// Kept separate from `GetStopArrivalsIntent` because the answer fits in one
/// spoken sentence with no snippet, which is what makes it usable on AirPods
/// and in CarPlay.
struct GetNextBusForLineIntent: AppIntent {
    @AppDependency(key: IntentServices.dependencyKey, default: IntentServices.live)
    private var services: IntentServices

    static var title: LocalizedStringResource {
        LocalizedStringResource("Get Next Bus On Line", table: "Intents")
    }

    static var description: IntentDescription {
        IntentDescription(
            LocalizedStringResource(
                "Check when a specific line next arrives at a stop.",
                table: "Intents"
            ),
            categoryName: LocalizedStringResource("Arrivals", table: "Intents")
        )
    }

    // Two declarations, because the App Intents metadata processor can't
    // read `#if` inside one. The extra parameter shows under "Show More".
    #if LIVE_ACTIVITIES
    static var parameterSummary: some ParameterSummary {
        Summary("Get the next line \(\.$line) bus at \(\.$stop)", table: "Intents") {
            \.$startsLiveActivity
        }
    }
    #else
    static var parameterSummary: some ParameterSummary {
        Summary("Get the next line \(\.$line) bus at \(\.$stop)", table: "Intents")
    }
    #endif

    @Parameter(
        title: LocalizedStringResource("Line", table: "Intents"),
        requestValueDialog: IntentDialog(
            LocalizedStringResource("Which line?", table: "Intents")
        )
    )
    var line: BusLineEntity

    @Parameter(
        title: LocalizedStringResource("Stop", table: "Intents"),
        requestValueDialog: IntentDialog(
            LocalizedStringResource("At which stop?", table: "Intents")
        )
    )
    var stop: BusStopEntity?

    #if LIVE_ACTIVITIES
    // Only builds with a Live Activity backend (the `personal` flavor) offer it.
    @Parameter(
        title: LocalizedStringResource("Start Live Activity", table: "Intents"),
        description: LocalizedStringResource(
            "Follows the line on the Lock Screen and in the Dynamic Island for 15 minutes.",
            table: "Intents"
        ),
        default: false
    )
    var startsLiveActivity: Bool
    #endif

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let target = try await resolvedStop()

        let estimations: [BusStopLineEstimation]
        do {
            estimations = try await services.estimations(forStop: target.id)
        } catch {
            throw IntentError(error)
        }

        let match = estimations.first { $0.lineID == line.id }

        #if LIVE_ACTIVITIES
        if startsLiveActivity { await startLiveActivity(at: target) }
        #endif

        return .result(
            dialog: ArrivalsFormatter.dialog(
                for: match, lineID: line.id, stopName: target.displayName
            )
        )
    }

    private func resolvedStop() async throws -> BusStopEntity {
        if let stop { return try validated(stop) }

        // Prefer a favourite the requested line actually serves — with one such
        // stop, "my stop" is unambiguous.
        let catalog = services.catalog
        let served = services.userDataStore.favoriteStops(in: catalog)
            .filter { stop in
                catalog.lines(servingStop: stop.id).contains { $0.id == line.id }
            }

        if served.count == 1 {
            return services.entity(for: served[0])
        }

        if served.count > 1 {
            return try await $stop.requestDisambiguation(
                among: services.entities(for: served),
                dialog: IntentDialog(
                    LocalizedStringResource(
                        "Which of your stops on line \(line.id)?",
                        table: "Intents"
                    )
                )
            )
        }

        let requested = try await $stop.requestValue(
            IntentDialog(
                LocalizedStringResource(
                    "Which stop on line \(line.id)?",
                    table: "Intents"
                )
            )
        )
        return try validated(requested)
    }

    private func validated(_ stop: BusStopEntity) throws -> BusStopEntity {
        let servesStop = services.catalog.lines(servingStop: stop.id)
            .contains { $0.id == line.id }

        guard servesStop else {
            throw IntentError.lineDoesNotServeStop(
                lineID: line.id,
                stopName: stop.displayName
            )
        }

        return stop
    }
}

#if LIVE_ACTIVITIES
/// In builds with a Live Activity backend, this intent is left out of the
/// intents extension, so iOS runs it in the app's process; as a
/// `LiveActivityIntent` it may then start an activity even while Aucorsa is
/// closed.
extension GetNextBusForLineIntent: LiveActivityIntent {
    /// Best-effort: the spoken answer doesn't depend on it.
    @MainActor
    fileprivate func startLiveActivity(at stop: BusStopEntity) async {
        guard let backend = LiveActivityBackend.configured else { return }
        do {
            let activity = try await BusArrivalActivityStarter.start(
                stopID: stop.id, lineID: line.id, name: stop.displayName,
                language: Bundle.main.preferredLocalizations.first == "es" ? "es" : "en",
                endingPrevious: { await BusArrivalActivityStarter.endAll(unregisteringFrom: backend) }
            )
            NotificationCenter.default.post(name: BusArrivalActivityStarter.didStartNotification, object: nil)
            try await BusArrivalActivityStarter.registerFirstPushToken(of: activity, with: backend)
            NSLog("Live Activity started from a shortcut and registered for server refreshes")
        } catch {
            NSLog("Live Activity from a shortcut failed: %@", String(reflecting: error))
        }
    }
}
#endif
