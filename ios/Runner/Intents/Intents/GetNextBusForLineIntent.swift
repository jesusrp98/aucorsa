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

    static var parameterSummary: some ParameterSummary {
        Summary("Get the next line \(\.$line) bus at \(\.$stop)", table: "Intents")
    }

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
