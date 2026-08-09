import CoreLocation
import Foundation
import os

/// Static stop and line data, decoded from the generated `transit_data.json`.
///
/// The JSON is produced by `tools/update_transit_data.py`, the same script that
/// writes the Dart sources, so both platforms are provably in sync (`--check`).
public struct TransitCatalog: Sendable {
    /// Bumped when the generated schema changes shape.
    public static let currentVersion = 1

    public let version: Int
    /// Ordered by stop id.
    public let stops: [BusStop]
    /// Ordered by the app's display order, which the estimation sort depends on.
    public let lines: [BusLine]

    // Derived indexes. Built once in `init` — roughly a thousand stops and forty
    // lines, so eager construction is cheaper than the bookkeeping to defer it.
    private let stopsByID: [Int: BusStop]
    private let lineIndexByID: [String: Int]
    private let lineIDsByStop: [Int: [String]]

    private static let logger = Logger(
        subsystem: "com.chechu.aucorsa", category: "TransitCatalog"
    )

    public init(version: Int, stops: [BusStop], lines: [BusLine]) {
        self.version = version
        self.stops = stops
        self.lines = lines

        self.stopsByID = Dictionary(
            stops.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first }
        )
        self.lineIndexByID = Dictionary(
            lines.enumerated().map { ($0.element.id, $0.offset) },
            uniquingKeysWith: { first, _ in first }
        )

        var lineIDsByStop: [Int: [String]] = [:]
        for line in lines {
            for stopID in line.stops {
                lineIDsByStop[stopID, default: []].append(line.id)
            }
        }
        self.lineIDsByStop = lineIDsByStop
    }

    // MARK: - Loading

    /// Decoded once per process. Falls back to an empty catalog rather than
    /// trapping: a broken resource should degrade an intent into a polite
    /// failure, not crash it. `TransitCatalogTests` asserts this is non-empty,
    /// so an actually-missing resource fails the tests instead of shipping.
    public static let shared: TransitCatalog = {
        do {
            return try loadBundled()
        } catch {
            logger.error("Failed to load transit_data.json: \(error)")
            return TransitCatalog(version: currentVersion, stops: [], lines: [])
        }
    }()

    public static func loadBundled() throws -> TransitCatalog {
        guard
            let url = Bundle.module.url(
                forResource: "transit_data", withExtension: "json"
            )
        else {
            throw CatalogError.resourceMissing
        }

        return try decode(Data(contentsOf: url))
    }

    public static func decode(_ data: Data) throws -> TransitCatalog {
        let catalog = try JSONDecoder().decode(TransitCatalog.self, from: data)

        guard catalog.version == currentVersion else {
            throw CatalogError.unsupportedVersion(catalog.version)
        }

        return catalog
    }

    public enum CatalogError: Error, Equatable {
        case resourceMissing
        case unsupportedVersion(Int)
    }

    public var isEmpty: Bool { stops.isEmpty || lines.isEmpty }

    // MARK: - Stops

    public func stop(id: Int) -> BusStop? { stopsByID[id] }

    public func stops(ids: [Int]) -> [BusStop] { ids.compactMap { stopsByID[$0] } }

    /// Diacritic- and case-insensitive stop search. Prefix matches rank above
    /// substring matches so "Ronda" surfaces "Ronda de los Tejares" first.
    public func searchStops(_ query: String, limit: Int = 20) -> [BusStop] {
        let needle = Self.fold(query)
        guard !needle.isEmpty else { return [] }

        var prefixMatches: [BusStop] = []
        var containsMatches: [BusStop] = []

        for stop in stops {
            let haystack = Self.fold(stop.name)
            if haystack.hasPrefix(needle) {
                prefixMatches.append(stop)
            } else if haystack.contains(needle) {
                containsMatches.append(stop)
            }
        }

        return Array((prefixMatches + containsMatches).prefix(limit))
    }

    /// Normalises for comparison: Spanish stop names are full of accents that
    /// users neither type nor pronounce distinctly to Siri.
    public static func fold(_ value: String) -> String {
        value.folding(
            options: [.diacriticInsensitive, .caseInsensitive, .widthInsensitive],
            locale: Locale(identifier: "es")
        )
        .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Lines

    public func line(id: String) -> BusLine? {
        guard let index = lineIndexByID[id] else { return nil }
        return lines[index]
    }

    /// Display-order index, or `nil` when unknown. The Dart equivalent
    /// (`BusLineUtils.getLineIndex`) returns -1; callers here treat `nil` as
    /// "sort last".
    public func lineIndex(of id: String) -> Int? { lineIndexByID[id] }

    public func lines(servingStop stopID: Int) -> [BusLine] {
        (lineIDsByStop[stopID] ?? []).compactMap(line(id:))
    }

    public func isActive(_ line: BusLine, on date: Date = Date()) -> Bool {
        guard line.rawEventID != nil else { return true }
        guard let eventID = line.eventID else { return false }
        return TransitEventsCalendar.currentEvents(on: date).contains(eventID)
    }

    /// Lines in service on `date`, applying the same event gate as
    /// `BusLineUtils.lines` in Dart. Without this, Siri would happily offer
    /// Feria lines in November.
    public func activeLines(on date: Date = Date()) -> [BusLine] {
        lines.filter { isActive($0, on: date) }
    }

    /// Sorts estimations into the app's line display order, matching
    /// `BusStopLineEstimation.compareTo` in Dart.
    public func sorted(
        _ estimations: [BusStopLineEstimation]
    ) -> [BusStopLineEstimation] {
        estimations.sorted {
            (lineIndex(of: $0.lineID) ?? .max) < (lineIndex(of: $1.lineID) ?? .max)
        }
    }
}

// MARK: - Codable

extension TransitCatalog: Codable {
    private enum CodingKeys: String, CodingKey {
        case version, stops, lines
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.init(
            version: try container.decode(Int.self, forKey: .version),
            stops: try container.decode([BusStop].self, forKey: .stops),
            lines: try container.decode([BusLine].self, forKey: .lines)
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(version, forKey: .version)
        try container.encode(stops, forKey: .stops)
        try container.encode(lines, forKey: .lines)
    }
}
