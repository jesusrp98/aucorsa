import AppIntents
import AucorsaKit
import Foundation
import SwiftUI

/// A bus line, as Siri and the Shortcuts app see it.
struct BusLineEntity: AppEntity, Identifiable, Hashable {
    /// AUCORSA's line id: mostly numeric ("1", "12") but also letters
    /// ("O1", "C2", "E", "N").
    let id: String
    let name: String
    let colorValue: UInt32

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(
            name: LocalizedStringResource("Bus Line", table: "Intents"),
            numericFormat: LocalizedStringResource(
                "\(placeholder: .int) bus lines", table: "Intents"
            )
        )
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(id)", subtitle: "\(name)")
    }

    var color: Color {
        Color(
            red: Double((colorValue >> 16) & 0xFF) / 255,
            green: Double((colorValue >> 8) & 0xFF) / 255,
            blue: Double(colorValue & 0xFF) / 255
        )
    }

    static var defaultQuery: BusLineQuery { BusLineQuery() }

    init(id: String, name: String, colorValue: UInt32) {
        self.id = id
        self.name = name
        self.colorValue = colorValue
    }

    init(line: BusLine) {
        self.init(id: line.id, name: line.name, colorValue: line.colorValue)
    }
}

/// Resolves bus lines for intent parameters.
///
/// Only lines actually in service are offered: the catalog carries thirteen
/// Feria-only lines that would otherwise show up in November.
struct BusLineQuery: EntityStringQuery {
    func entities(for identifiers: [String]) async throws -> [BusLineEntity] {
        let catalog = TransitCatalog.shared
        return identifiers
            .compactMap { catalog.line(id: $0) }
            .filter { catalog.isActive($0) }
            .map(BusLineEntity.init(line:))
    }

    func entities(matching string: String) async throws -> [BusLineEntity] {
        let catalog = TransitCatalog.shared
        let needle = TransitCatalog.fold(string)
        guard !needle.isEmpty else { return [] }

        return catalog.activeLines()
            .filter {
                // Exact id first ("the 3"), then anything in the route name
                // ("Tendillas").
                TransitCatalog.fold($0.id) == needle
                    || TransitCatalog.fold($0.name).contains(needle)
            }
            .map(BusLineEntity.init(line:))
    }

    func suggestedEntities() async throws -> [BusLineEntity] {
        TransitCatalog.shared.activeLines().map(BusLineEntity.init(line:))
    }
}
