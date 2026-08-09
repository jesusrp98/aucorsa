import AppIntents
import AucorsaKit
import CoreLocation
import Foundation

/// A bus stop, as Siri and the Shortcuts app see it.
struct BusStopEntity: AppEntity, Identifiable, Hashable {
    let id: Int
    /// The name AUCORSA publishes.
    let officialName: String
    /// The label the user gave this stop in the app, if any.
    let customName: String?
    let lineIDs: [String]
    let latitude: Double
    let longitude: Double

    /// What the user calls this stop. Siri speaks this and matches against it.
    var displayName: String { customName ?? officialName }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(
            name: LocalizedStringResource("Bus Stop", table: "Intents"),
            numericFormat: LocalizedStringResource(
                "\(placeholder: .int) bus stops", table: "Intents"
            )
        )
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(displayName)",
            subtitle: subtitle.map { "\($0)" }
        )
    }

    /// When the user renamed the stop, show the official name underneath so
    /// "Casa" is still identifiable during disambiguation. Otherwise list the
    /// lines, which is the next most useful way to tell two stops apart.
    private var subtitle: String? {
        if customName != nil { return officialName }
        guard !lineIDs.isEmpty else { return nil }
        return lineIDs.joined(separator: " · ")
    }

    static var defaultQuery: BusStopQuery { BusStopQuery() }
}

extension BusStopEntity {
    /// Builds an entity from catalog data plus the user's own customisations.
    init(stop: BusStop, userData: UserData, catalog: TransitCatalog) {
        self.init(
            id: stop.id,
            officialName: stop.name,
            customName: UserDataStore.shared.customName(for: stop.id, in: userData),
            lineIDs: catalog.lines(servingStop: stop.id)
                .filter { catalog.isActive($0) }
                .map(\.id),
            latitude: stop.latitude,
            longitude: stop.longitude
        )
    }

    /// Batch conversion. Reads the user data file once rather than per stop —
    /// a query can easily touch a few dozen entities.
    static func entities(
        for stops: [BusStop],
        catalog: TransitCatalog = .shared
    ) -> [BusStopEntity] {
        let userData = UserDataStore.shared.load()
        return stops.map {
            BusStopEntity(stop: $0, userData: userData, catalog: catalog)
        }
    }
}
