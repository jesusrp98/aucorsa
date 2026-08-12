import Foundation
import os

/// Per-stop customisation the user made in the app.
public struct CustomStopData: Codable, Hashable, Sendable {
    public let name: String?
    public let icon: Int?

    public init(name: String?, icon: Int?) {
        self.name = name
        self.icon = icon
    }
}

/// The slice of app state the intents need, as written by Flutter.
///
/// Mirrors `FavoriteStopsCubit` and `BusStopCustomDataCubit`. Those are
/// `HydratedCubit`s, and their storage format is an implementation detail of
/// the package, so the Dart side mirrors into this file on write instead of
/// Swift reading HydratedBloc's own store.
public struct UserData: Codable, Hashable, Sendable {
    public static let currentVersion = 1

    public let version: Int
    public let favorites: [Int]
    /// Keyed by stop id as a string, because JSON object keys are strings.
    public let customNames: [String: CustomStopData]

    public static let empty = UserData(
        version: currentVersion, favorites: [], customNames: [:]
    )

    public init(version: Int, favorites: [Int], customNames: [String: CustomStopData]) {
        self.version = version
        self.favorites = favorites
        self.customNames = customNames
    }
}

/// Reads `user_data.json` out of the shared App Group container.
public struct UserDataStore: Sendable {
    public static let shared = UserDataStore()

    private static let logger = Logger(
        subsystem: "com.chechu.aucorsa", category: "UserDataStore"
    )

    private let url: URL?

    public init(url: URL? = AppGroup.userDataURL) {
        self.url = url
    }

    /// Read fresh every time. The file is a few kilobytes and an intent process
    /// is short-lived, so caching would only risk serving a stale favourite.
    public func load() -> UserData {
        guard let url, FileManager.default.fileExists(atPath: url.path) else {
            return .empty
        }

        do {
            let data = try Data(contentsOf: url)
            let userData = try JSONDecoder().decode(UserData.self, from: data)

            guard userData.version == UserData.currentVersion else {
                Self.logger.error(
                    "Unsupported user_data.json version \(userData.version)"
                )
                return .empty
            }

            return userData
        } catch {
            Self.logger.error("Failed to read user_data.json: \(error)")
            return .empty
        }
    }

    /// Writes the mirror. Called from the Flutter side of the bridge whenever
    /// favourites or custom names change; the reader and writer live together so
    /// the file shape is defined exactly once.
    ///
    /// Written to a sibling temporary file and moved into place, so a reader in
    /// another process never observes a half-written file.
    public enum StoreError: Error, Equatable {
        /// The App Group container could not be resolved — almost always
        /// because the group is not provisioned for this build. Distinct from a
        /// write failure so the Flutter side can report it as a setup problem
        /// rather than a transient error.
        case containerUnavailable
    }

    public func save(_ userData: UserData) throws {
        guard let url else { throw StoreError.containerUnavailable }

        let data = try JSONEncoder().encode(userData)
        let temporaryURL = url.deletingLastPathComponent()
            .appendingPathComponent(".user_data.\(UUID().uuidString).json")

        try data.write(to: temporaryURL, options: .atomic)
        _ = try FileManager.default.replaceItemAt(url, withItemAt: temporaryURL)
    }

    public func favoriteStopIDs() -> [Int] { load().favorites }

    /// Favourite stops resolved against the catalog, skipping any the catalog
    /// no longer knows (a stop can be retired between data updates).
    public func favoriteStops(
        in catalog: TransitCatalog = .shared
    ) -> [BusStop] {
        catalog.stops(ids: load().favorites)
    }

    /// The name the user gave this stop, if any.
    public func customName(for stopID: Int, in userData: UserData? = nil) -> String? {
        let data = userData ?? load()
        guard let name = data.customNames[String(stopID)]?.name else { return nil }

        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    /// What the user calls this stop: their own label when set, otherwise the
    /// official name. This is what Siri should say and match against.
    public func displayName(for stop: BusStop, in userData: UserData? = nil) -> String {
        customName(for: stop.id, in: userData) ?? stop.name
    }
}
