import ActivityKit
import AucorsaKit
import Foundation

@available(iOS 16.2, *)
struct BusArrivalAttributes: ActivityAttributes {
    typealias ContentState = BusArrivalSnapshot
    static let sessionDuration: TimeInterval = 15 * 60

    let stopID: Int
    let stopName: String
    let preferredLineID: String
    let language: String
    let endsAt: Double
    let sessionID: String
    // Absent in the original 30-minute sessions, which can survive an upgrade.
    let startedAt: Double?

    var deadline: Double {
        min(endsAt, (startedAt ?? endsAt - 30 * 60) + Self.sessionDuration)
    }

    var hasExpired: Bool { deadline <= Date.now.timeIntervalSince1970 }

    var url: URL { URL(string: "aucorsa://app/stops/\(stopID)")! }
    var isSpanish: Bool { language == "es" }
}
