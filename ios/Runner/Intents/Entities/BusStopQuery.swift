import AppIntents
import AucorsaKit
import Foundation

/// Resolves bus stops for intent parameters.
///
/// Matching covers the user's own stop labels as well as the official names.
/// People already rename stops to "Casa" and "Trabajo" in the app, so this is
/// what makes *"¿cuándo pasa el bus en casa?"* resolve without the user having
/// to recall what AUCORSA calls the stop.
struct BusStopQuery: EntityStringQuery {
    private static let matchLimit = 20

    func entities(for identifiers: [Int]) async throws -> [BusStopEntity] {
        let catalog = TransitCatalog.shared
        return BusStopEntity.entities(
            for: identifiers.compactMap { catalog.stop(id: $0) },
            catalog: catalog
        )
    }

    func entities(matching string: String) async throws -> [BusStopEntity] {
        let catalog = TransitCatalog.shared
        let userData = UserDataStore.shared.load()
        let needle = TransitCatalog.fold(string)

        guard !needle.isEmpty else { return [] }

        // Custom names first: if the user asked for "casa" they mean their
        // stop, not whatever official name happens to contain those letters.
        var matchedIDs: [Int] = []
        var seen = Set<Int>()

        for (rawID, custom) in userData.customNames {
            guard
                let stopID = Int(rawID),
                let name = custom.name,
                TransitCatalog.fold(name).contains(needle),
                seen.insert(stopID).inserted
            else { continue }

            matchedIDs.append(stopID)
        }

        for stop in catalog.searchStops(string, limit: Self.matchLimit) {
            if seen.insert(stop.id).inserted { matchedIDs.append(stop.id) }
        }

        let stops = matchedIDs.prefix(Self.matchLimit).compactMap { catalog.stop(id: $0) }
        return stops.map { BusStopEntity(stop: $0, userData: userData, catalog: catalog) }
    }

    /// The user's favourites. Without this, parameter disambiguation would show
    /// an undifferentiated list of several hundred stops.
    func suggestedEntities() async throws -> [BusStopEntity] {
        let catalog = TransitCatalog.shared
        return BusStopEntity.entities(
            for: UserDataStore.shared.favoriteStops(in: catalog),
            catalog: catalog
        )
    }
}
