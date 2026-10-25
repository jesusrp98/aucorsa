import Foundation

/// Small, immutable snapshot shared by the app and its ActivityKit extension.
/// The timestamp always belongs to the last successful network response.
public struct BusArrivalSnapshot: Codable, Hashable, Sendable {
    public struct Line: Codable, Hashable, Sendable, Identifiable {
        public let lineID: String
        public let arrivals: [Int]
        public var id: String { lineID }

        public init(lineID: String, arrivals: [Int]) {
            self.lineID = lineID
            self.arrivals = Array(arrivals.filter { (0...1440).contains($0) }.prefix(2))
        }

        private enum CodingKeys: String, CodingKey { case lineID, arrivals }

        /// Pushed content comes from the backend, so it gets the same limits.
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.init(lineID: try container.decode(String.self, forKey: .lineID),
                      arrivals: try container.decode([Int].self, forKey: .arrivals))
        }
    }

    public let fetchedAt: Double
    public let lines: [Line]
    /// Optional for compatibility with sessions created before live renaming.
    public let stopName: String?

    public init(fetchedAt: Double, lines: [Line], stopName: String? = nil) {
        self.fetchedAt = fetchedAt
        self.lines = Array(lines.prefix(3))
        self.stopName = stopName.map { String($0.prefix(80)) }
    }

    private enum CodingKeys: String, CodingKey { case fetchedAt, lines, stopName }

    /// Pushed content comes from the backend, so it gets the same limits.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(fetchedAt: try container.decode(Double.self, forKey: .fetchedAt),
                  lines: try container.decode([Line].self, forKey: .lines),
                  stopName: try container.decodeIfPresent(String.self, forKey: .stopName))
    }

    public init(estimations: [BusStopLineEstimation], preferredLineID: String, now: Date = .now) {
        let preferred = estimations.first { $0.lineID == preferredLineID }
        let others = estimations.filter { $0.lineID != preferredLineID }
        self.init(fetchedAt: now.timeIntervalSince1970, lines: [
            Line(lineID: preferredLineID, arrivals: preferred?.arrivals ?? [])
        ] + others.prefix(2).map { Line(lineID: $0.lineID, arrivals: $0.arrivals) })
    }

    public func staleDate(endingAt end: Double) -> Date {
        Date(timeIntervalSince1970: min(fetchedAt + 90, end))
    }

    /// Renaming must not make old estimates appear freshly fetched.
    public func withStopName(_ name: String?) -> Self {
        Self(fetchedAt: fetchedAt, lines: lines, stopName: name)
    }
}
