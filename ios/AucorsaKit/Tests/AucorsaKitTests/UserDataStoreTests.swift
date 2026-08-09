import Foundation
import Testing

@testable import AucorsaKit

@Suite("User data store")
struct UserDataStoreTests {
    /// Writes a payload to a temporary file and returns a store reading it.
    static func store(writing json: String) throws -> UserDataStore {
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("user_data_\(UUID().uuidString).json")
        try Data(json.utf8).write(to: url)
        return UserDataStore(url: url)
    }

    @Test("Reads favourites and custom names")
    func readsPayload() throws {
        let store = try Self.store(
            writing: #"""
            {"version":1,"favorites":[105,8],
             "customNames":{"105":{"name":"Casa","icon":3}}}
            """#
        )

        #expect(store.favoriteStopIDs() == [105, 8])
        #expect(store.customName(for: 105) == "Casa")
        #expect(store.customName(for: 8) == nil)
    }

    @Test("Display name prefers the user's own label")
    func displayNamePrefersCustom() throws {
        let store = try Self.store(
            writing: #"{"version":1,"favorites":[],"customNames":{"105":{"name":"Trabajo","icon":null}}}"#
        )

        let labelled = BusStop(id: 105, name: "Fátima", latitude: 37.9, longitude: -4.79)
        let plain = BusStop(id: 7, name: "Pintor Espinosa", latitude: 37.9, longitude: -4.79)

        #expect(store.displayName(for: labelled) == "Trabajo")
        #expect(store.displayName(for: plain) == "Pintor Espinosa")
    }

    @Test("Blank custom names fall back to the official name")
    func blankCustomName() throws {
        let store = try Self.store(
            writing: #"{"version":1,"favorites":[],"customNames":{"105":{"name":"   ","icon":null}}}"#
        )

        let stop = BusStop(id: 105, name: "Fátima", latitude: 37.9, longitude: -4.79)
        #expect(store.customName(for: 105) == nil)
        #expect(store.displayName(for: stop) == "Fátima")
    }

    @Test("A missing file reads as empty rather than failing")
    func missingFile() {
        let store = UserDataStore(
            url: URL(fileURLWithPath: "/nonexistent/user_data.json")
        )
        #expect(store.favoriteStopIDs().isEmpty)
    }

    @Test("A nil container (no App Group entitlement) reads as empty")
    func missingContainer() {
        #expect(UserDataStore(url: nil).favoriteStopIDs().isEmpty)
    }

    @Test("Malformed JSON reads as empty rather than throwing into an intent")
    func malformedPayload() throws {
        let store = try Self.store(writing: "{ not json")
        #expect(store.favoriteStopIDs().isEmpty)
    }

    @Test("A future schema version is ignored")
    func futureVersion() throws {
        let store = try Self.store(
            writing: #"{"version":99,"favorites":[1,2],"customNames":{}}"#
        )
        #expect(store.favoriteStopIDs().isEmpty)
    }

    @Test("Favourites resolve against the catalog, skipping retired stops")
    func favouritesResolve() throws {
        let catalog = TransitCatalog(
            version: 1,
            stops: [BusStop(id: 105, name: "Fátima", latitude: 37.9, longitude: -4.79)],
            lines: []
        )
        let store = try Self.store(
            writing: #"{"version":1,"favorites":[105,999999],"customNames":{}}"#
        )

        let stops = store.favoriteStops(in: catalog)
        #expect(stops.map(\.id) == [105])
    }
}

@Suite("Events calendar")
struct TransitEventsCalendarTests {
    static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        Calendar.current.date(
            from: DateComponents(year: year, month: month, day: day)
        )!
    }

    @Test("Feria is active inside its window")
    func feriaActive() {
        #expect(
            TransitEventsCalendar.currentEvents(on: Self.date(2026, 5, 20))
                .contains(.feria)
        )
    }

    @Test(
        "Feria is inactive outside its window",
        arguments: [(2026, 1, 15), (2026, 5, 1), (2026, 7, 1), (2026, 11, 30)]
    )
    func feriaInactive(year: Int, month: Int, day: Int) {
        #expect(
            !TransitEventsCalendar.currentEvents(on: Self.date(year, month, day))
                .contains(.feria)
        )
    }

    @Test("Event-gated lines are filtered out of season")
    func activeLinesFiltersEventLines() {
        let catalog = TransitCatalog(
            version: 1,
            stops: [],
            lines: [
                BusLine(id: "1", name: "Regular", colorValue: 0, stops: [1]),
                BusLine(id: "21", name: "Feria", colorValue: 0, stops: [1], rawEventID: "feria")
            ]
        )

        #expect(catalog.activeLines(on: Self.date(2026, 11, 1)).map(\.id) == ["1"])
        #expect(catalog.activeLines(on: Self.date(2026, 5, 20)).map(\.id) == ["1", "21"])
    }

    @Test("A line gated by an unrecognised event is treated as out of service")
    func unknownEventIsInactive() {
        let line = BusLine(
            id: "99", name: "Mystery", colorValue: 0, stops: [1], rawEventID: "carnaval"
        )
        let catalog = TransitCatalog(version: 1, stops: [], lines: [line])

        #expect(line.hasUnrecognisedEvent)
        // Offering a line we cannot reason about is worse than omitting it.
        #expect(catalog.activeLines(on: Self.date(2026, 5, 20)).isEmpty)
    }
}

@Suite("Nonce parsing")
struct NonceParsingTests {
    @Test("Extracts the nonce from homepage markup")
    func parsesNonce() {
        let homepage = #"var ajax_vars = {"api_light":"x","ajax_nonce":"311267f2d0","post_id":"12"};"#
        #expect(AucorsaClient.parseNonce(homepage) == "311267f2d0")
    }

    @Test("Tolerates whitespace around the colon")
    func parsesWithWhitespace() {
        #expect(AucorsaClient.parseNonce(#""ajax_nonce"  :   "abc123""#) == "abc123")
    }

    @Test("Returns nil when the homepage has no nonce")
    func missingNonce() {
        #expect(AucorsaClient.parseNonce("<html>nothing here</html>") == nil)
    }
}
