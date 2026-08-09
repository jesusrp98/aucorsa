import Foundation
import Testing

@testable import AucorsaKit

@Suite("Transit catalog")
struct TransitCatalogTests {
    let catalog = TransitCatalog.shared

    /// `TransitCatalog.shared` swallows a load failure and returns an empty
    /// catalog so intents degrade politely. That makes this test the thing that
    /// actually catches a missing or malformed resource.
    @Test("The bundled catalog loads and is populated")
    func bundledCatalogLoads() throws {
        #expect(!catalog.isEmpty)
        #expect(catalog.version == TransitCatalog.currentVersion)
        #expect(catalog.stops.count > 500)
        #expect(catalog.lines.count > 20)
    }

    @Test("Stops are unique and carry plausible Cordoba coordinates")
    func stopsAreWellFormed() {
        let ids = Set(catalog.stops.map(\.id))
        #expect(ids.count == catalog.stops.count)

        for stop in catalog.stops {
            #expect(!stop.name.isEmpty)
            // Cordoba sits near 37.88 N, -4.78 E; a generous box catches a
            // swapped lat/lon or a unit mistake without being brittle.
            #expect((37.5...38.2).contains(stop.latitude))
            #expect((-5.2...(-4.4)).contains(stop.longitude))
        }
    }

    @Test("Every line references stops the catalog knows")
    func lineStopsResolve() {
        for line in catalog.lines {
            #expect(!line.stops.isEmpty)
            for stopID in line.stops {
                #expect(catalog.stop(id: stopID) != nil, "line \(line.id) -> stop \(stopID)")
            }
        }
    }

    @Test("Line lookup and display order round-trip")
    func lineLookup() throws {
        let first = try #require(catalog.lines.first)
        #expect(catalog.line(id: first.id) == first)
        #expect(catalog.lineIndex(of: first.id) == 0)
        #expect(catalog.lineIndex(of: "definitely-not-a-line") == nil)
    }

    @Test("Colour unpacks to the same value the Dart source uses")
    func colourUnpacking() throws {
        // Dart writes `Color(0xFF166C4B)` for line 1.
        let line = try #require(catalog.line(id: "1"))
        #expect(line.colorValue == 0x166C4B)
        #expect(abs(line.red - 22.0 / 255) < 0.0001)
        #expect(abs(line.green - 108.0 / 255) < 0.0001)
        #expect(abs(line.blue - 75.0 / 255) < 0.0001)
    }

    @Test("Stop search ignores case and accents")
    func searchFolding() throws {
        let accented = try #require(
            catalog.stops.first { $0.name.contains("á") || $0.name.contains("ó") }
        )
        let folded = TransitCatalog.fold(accented.name)

        let results = catalog.searchStops(folded)
        #expect(results.contains { $0.id == accented.id })

        // Upper-cased and accent-stripped queries must find the same stop.
        #expect(catalog.searchStops(folded.uppercased()).contains { $0.id == accented.id })
    }

    @Test("Search ranks prefix matches ahead of substring matches")
    func searchRanking() throws {
        let stop = try #require(catalog.stops.first { $0.name.split(separator: " ").count > 1 })
        let firstWord = String(stop.name.split(separator: " ")[0])

        let results = catalog.searchStops(firstWord)
        try #require(!results.isEmpty)
        #expect(TransitCatalog.fold(results[0].name).hasPrefix(TransitCatalog.fold(firstWord)))
    }

    @Test("Empty search returns nothing rather than everything")
    func emptySearch() {
        #expect(catalog.searchStops("").isEmpty)
        #expect(catalog.searchStops("   ").isEmpty)
    }

    @Test("Lines serving a stop agree with the lines' own stop lists")
    func linesServingStop() throws {
        let line = try #require(catalog.lines.first)
        let stopID = try #require(line.stops.first)
        #expect(catalog.lines(servingStop: stopID).contains { $0.id == line.id })
    }

    @Test("Estimations sort into the app's line display order")
    func estimationSorting() throws {
        try #require(catalog.lines.count >= 3)
        let ids = catalog.lines.prefix(3).map(\.id)

        let shuffled = [
            BusStopLineEstimation(lineID: ids[2], arrivals: [1]),
            BusStopLineEstimation(lineID: ids[0], arrivals: [2]),
            BusStopLineEstimation(lineID: ids[1], arrivals: [3])
        ]

        #expect(catalog.sorted(shuffled).map(\.lineID) == Array(ids))
    }

    @Test("Unknown lines sort last instead of crashing")
    func unknownLineSortsLast() throws {
        let known = try #require(catalog.lines.first).id
        let sorted = catalog.sorted([
            BusStopLineEstimation(lineID: "ZZZ", arrivals: [1]),
            BusStopLineEstimation(lineID: known, arrivals: [2])
        ])
        #expect(sorted.map(\.lineID) == [known, "ZZZ"])
    }

    @Test("Rejects a catalog written by a future generator")
    func versionMismatch() throws {
        let payload = #"{"version":999,"stops":[],"lines":[]}"#
        #expect(throws: TransitCatalog.CatalogError.unsupportedVersion(999)) {
            try TransitCatalog.decode(Data(payload.utf8))
        }
    }
}
