import Foundation

/// A bus line.
///
/// Mirrors `lib/common/models/bus_line.dart`. Route geometry (`linePaths` in the
/// Dart source) is deliberately absent: it is ~750K of map-rendering data that
/// nothing on this side of the bridge draws.
public struct BusLine: Codable, Hashable, Sendable, Identifiable {
    public let id: String
    public let name: String
    /// Packed 0xRRGGBB. Presentation layers build their own colour type from it
    /// so this package stays free of SwiftUI and UIKit.
    public let colorValue: UInt32
    public let stops: [Int]
    /// Raw event slug from the generator. Kept as a string rather than the enum
    /// so one unrecognised value cannot fail the decode of the entire catalog.
    /// `tools/update_transit_data.py` validates it against the known set, so an
    /// unknown value here means the generator and this package have drifted.
    public let rawEventID: String?

    public init(
        id: String,
        name: String,
        colorValue: UInt32,
        stops: [Int],
        rawEventID: String? = nil
    ) {
        self.id = id
        self.name = name
        self.colorValue = colorValue
        self.stops = stops
        self.rawEventID = rawEventID
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case colorValue = "color"
        case stops
        case rawEventID = "event"
    }

    /// Non-nil when the line only runs during a calendar event, e.g. `feria`.
    public var eventID: TransitEventID? {
        rawEventID.flatMap(TransitEventID.init(rawValue:))
    }

    /// True when the line is gated by an event this build does not know about.
    /// Such a line is treated as out of service rather than always in service:
    /// offering a Feria line in November is worse than omitting one.
    public var hasUnrecognisedEvent: Bool {
        rawEventID != nil && eventID == nil
    }

    public var red: Double { Double((colorValue >> 16) & 0xFF) / 255 }
    public var green: Double { Double((colorValue >> 8) & 0xFF) / 255 }
    public var blue: Double { Double(colorValue & 0xFF) / 255 }
}
