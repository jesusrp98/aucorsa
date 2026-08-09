import AppIntents
import AucorsaKit
import CoreSpotlight
import CryptoKit
import Foundation
import os

/// Puts bus stops into the Spotlight semantic index.
///
/// Not required by the Tier 1/2 intents, but it is the foundation any later
/// Apple Intelligence work builds on: personal context is driven by indexed
/// entities, not by intents. Cheap to add once the entity exists.
@available(iOS 18.0, *)
extension BusStopEntity: IndexedEntity {
    var attributeSet: CSSearchableItemAttributeSet {
        let attributes = CSSearchableItemAttributeSet(contentType: .item)
        attributes.title = displayName
        attributes.displayName = displayName
        attributes.latitude = latitude as NSNumber
        attributes.longitude = longitude as NSNumber
        attributes.supportsNavigation = true

        // Both names are searchable so the official name still finds a stop the
        // user renamed, and vice versa.
        var keywords = lineIDs
        keywords.append(officialName)
        if let customName { keywords.append(customName) }
        attributes.keywords = keywords

        attributes.contentDescription = lineIDs.isEmpty
            ? officialName
            : "\(officialName) · \(lineIDs.joined(separator: " "))"

        return attributes
    }
}

/// Donates stops to Spotlight, skipping the work when nothing has changed.
enum SpotlightIndexer {
    fileprivate static let fingerprintKey = "aucorsa.spotlight.fingerprint"

    fileprivate static let logger = Logger(
        subsystem: "com.chechu.aucorsa", category: "SpotlightIndexer"
    )

    @available(iOS 18.0, *)
    private static let coordinator = SpotlightIndexCoordinator()

    /// Reindexes if the catalog or the user's own labels have changed.
    ///
    /// Called after an App Group sync, which happens on launch and whenever
    /// favourites or custom names change — so a rename shows up in Spotlight
    /// without a full reindex on every app start.
    static func indexIfNeeded() {
        guard #available(iOS 18.0, *) else { return }

        let catalog = TransitCatalog.shared
        guard !catalog.isEmpty else { return }

        let userData = UserDataStore.shared.load()
        let fingerprint = fingerprint(for: catalog, userData: userData)

        let entities = BusStopEntity.entities(for: catalog.stops, catalog: catalog)
        let favoriteIDs = Set(userData.favorites)

        Task {
            await coordinator.request(
                .init(
                    fingerprint: fingerprint,
                    entities: entities,
                    favoriteIDs: favoriteIDs
                )
            )
        }
    }

    /// Stable change detector covering every indexed field and favourite
    /// priority. Swift's `hashValue` is intentionally random between processes,
    /// so a persisted fingerprint must use a deterministic digest.
    private static func fingerprint(
        for catalog: TransitCatalog, userData: UserData
    ) -> String {
        var components = ["schema=2", "catalog=\(catalog.version)"]

        components.append(contentsOf: catalog.stops.map {
            "stop:\($0.id):\($0.name):\($0.latitude):\($0.longitude)"
        })
        components.append(contentsOf: catalog.lines.map {
            "line:\($0.id):\($0.name):\($0.colorValue):\($0.rawEventID ?? ""):\($0.stops.map(String.init).joined(separator: ","))"
        })

        let labels = userData.customNames
            .compactMap { key, value -> String? in
                guard let name = value.name?.trimmingCharacters(
                    in: .whitespacesAndNewlines
                ), !name.isEmpty else { return nil }
                return "label:\(key):\(name)"
            }
            .sorted()
        components.append(contentsOf: labels)
        components.append(
            "favorites:\(userData.favorites.sorted().map(String.init).joined(separator: ","))"
        )

        let digest = SHA256.hash(data: Data(components.joined(separator: "\n").utf8))
        return "v2-" + digest.map { String(format: "%02x", $0) }.joined()
    }
}

@available(iOS 18.0, *)
enum BusStopSpotlightIndex {
    static let name = "AucorsaBusStops"

    private static var index: CSSearchableIndex {
        CSSearchableIndex(name: name)
    }

    /// Replaces or updates entities, indexing favourites at a higher priority so
    /// the system can surface the stops that matter most to this user.
    static func index(
        _ entities: [BusStopEntity],
        favoriteIDs: Set<Int>,
        replacingAll: Bool
    ) async throws {
        let searchableIndex = index

        if replacingAll {
            try await searchableIndex.deleteAppEntities(ofType: BusStopEntity.self)
        }

        let favorites = entities.filter { favoriteIDs.contains($0.id) }
        let others = entities.filter { !favoriteIDs.contains($0.id) }

        if !others.isEmpty {
            try await searchableIndex.indexAppEntities(others)
        }
        if !favorites.isEmpty {
            try await searchableIndex.indexAppEntities(favorites, priority: 10)
        }
    }
}

@available(iOS 18.0, *)
private actor SpotlightIndexCoordinator {
    struct Request: Sendable {
        let fingerprint: String
        let entities: [BusStopEntity]
        let favoriteIDs: Set<Int>
    }

    private var pending: Request?
    private var isIndexing = false

    func request(_ request: Request) async {
        let defaults = AppGroup.defaults ?? .standard
        guard defaults.string(forKey: SpotlightIndexer.fingerprintKey) != request.fingerprint
        else { return }

        // Retain only the newest state while an index pass is running. The
        // active pass completes atomically, then the loop catches up once.
        pending = request
        guard !isIndexing else { return }

        isIndexing = true
        defer { isIndexing = false }

        while let next = pending {
            pending = nil

            guard defaults.string(forKey: SpotlightIndexer.fingerprintKey) != next.fingerprint
            else { continue }

            do {
                try await BusStopSpotlightIndex.index(
                    next.entities,
                    favoriteIDs: next.favoriteIDs,
                    replacingAll: true
                )
                defaults.set(next.fingerprint, forKey: SpotlightIndexer.fingerprintKey)
                SpotlightIndexer.logger.debug(
                    "Indexed \(next.entities.count) stops into Spotlight"
                )
            } catch {
                // Indexing is an enhancement; failing it must not affect the app.
                SpotlightIndexer.logger.error("Spotlight indexing failed: \(error)")
            }
        }
    }
}
