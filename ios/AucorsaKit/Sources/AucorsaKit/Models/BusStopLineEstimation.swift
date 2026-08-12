import Foundation

/// Arrival estimations for one line at one stop.
///
/// Mirrors `lib/common/models/bus_stop_line_estimation.dart`. The upstream API
/// is minute-granular, so arrivals are whole minutes rather than `Duration`.
public struct BusStopLineEstimation: Hashable, Sendable, Identifiable {
    public let lineID: String
    /// Minutes until arrival, in the order the API returned them (soonest first).
    public let arrivals: [Int]

    public var id: String { lineID }

    public init(lineID: String, arrivals: [Int]) {
        self.lineID = lineID
        self.arrivals = arrivals
    }

    public var nextArrival: Int? { arrivals.first }
}
