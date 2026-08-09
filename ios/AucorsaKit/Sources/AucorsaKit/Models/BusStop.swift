import CoreLocation
import Foundation

/// A single bus stop.
///
/// Mirrors the data generated into `lib/common/utils/bus_stop_utils.dart`, minus
/// anything only the map needs.
public struct BusStop: Codable, Hashable, Sendable, Identifiable {
    public let id: Int
    public let name: String
    public let latitude: Double
    public let longitude: Double

    public init(id: Int, name: String, latitude: Double, longitude: Double) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
    }

    // Short keys: the generated catalog carries ~1000 stops, and the verbose
    // spellings cost about 20K for nothing.
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case latitude = "lat"
        case longitude = "lon"
    }

    public var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
