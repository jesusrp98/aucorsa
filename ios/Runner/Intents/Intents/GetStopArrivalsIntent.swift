import AppIntents
import AucorsaKit
import Foundation

/// "When's the next bus at Ronda de los Tejares?"
///
/// The flagship data intent. Runs entirely in this process — no Flutter engine
/// is booted — so it works from Spotlight, the Shortcuts app, or a cold start
/// with the app force-quit.
struct GetStopArrivalsIntent: AppIntent {
    @AppDependency(key: IntentServices.dependencyKey, default: IntentServices.live)
    private var services: IntentServices

    static var title: LocalizedStringResource {
        LocalizedStringResource("Get Bus Arrivals", table: "Intents")
    }

    static var description: IntentDescription {
        IntentDescription(
            LocalizedStringResource(
                "Check when the next buses arrive at a stop.", table: "Intents"
            ),
            categoryName: LocalizedStringResource("Arrivals", table: "Intents")
        )
    }

    static var parameterSummary: some ParameterSummary {
        Summary("Get bus arrivals at \(\.$stop)", table: "Intents")
    }

    /// Optional so the intent can fall back to a single favourite before asking.
    @Parameter(
        title: LocalizedStringResource("Stop", table: "Intents"),
        requestValueDialog: IntentDialog(
            LocalizedStringResource("Which stop?", table: "Intents")
        )
    )
    var stop: BusStopEntity?

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        let target = try await resolvedStop()

        let estimations: [BusStopLineEstimation]
        do {
            estimations = try await services.estimations(forStop: target.id)
        } catch {
            throw IntentError(error)
        }

        return .result(
            dialog: ArrivalsFormatter.dialog(
                for: estimations, stopName: target.displayName
            ),
            view: ArrivalsSnippetView(estimations: estimations)
            // The snippet's render environment reports light regardless of the
            // device setting, so the appearance read here — in the app's own
            // process — is forced onto it.
            .snippetColorScheme(SystemAppearance.colorScheme)
        )
    }

    /// Uses the given stop; failing that the user's only favourite, since with
    /// one favourite "the bus stop" is unambiguous; otherwise asks.
    private func resolvedStop() async throws -> BusStopEntity {
        if let stop { return stop }

        let favorites = services.userDataStore.favoriteStops(in: services.catalog)
        if favorites.count == 1 {
            return services.entity(for: favorites[0])
        }

        return try await $stop.requestValue()
    }
}
