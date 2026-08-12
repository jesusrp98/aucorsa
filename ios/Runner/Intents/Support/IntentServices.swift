import AucorsaKit
import Foundation

protocol ArrivalEstimating: Sendable {
    func estimations(forStop stopID: Int) async throws -> [BusStopLineEstimation]
}

extension AucorsaClient: ArrivalEstimating {}

/// Runtime dependencies used by the data intents.
///
/// Keeping them behind one sendable value lets tests replace the live network
/// client and stores through `AppDependencyManager` without changing App Intent
/// metadata or adding test-only initializers to the intents themselves.
struct IntentServices: Sendable {
    static let dependencyKey = "com.chechu.aucorsa.intent-services"

    static let live = IntentServices(
        catalog: .shared,
        userDataStore: .shared,
        arrivalProvider: AucorsaClient.shared
    )

    let catalog: TransitCatalog
    let userDataStore: UserDataStore
    let arrivalProvider: any ArrivalEstimating

    func estimations(forStop stopID: Int) async throws -> [BusStopLineEstimation] {
        try await arrivalProvider.estimations(forStop: stopID)
    }

    func entity(for stop: BusStop) -> BusStopEntity {
        BusStopEntity(
            stop: stop,
            userData: userDataStore.load(),
            catalog: catalog
        )
    }

    func entities(for stops: [BusStop]) -> [BusStopEntity] {
        let userData = userDataStore.load()
        return stops.map {
            BusStopEntity(stop: $0, userData: userData, catalog: catalog)
        }
    }
}
