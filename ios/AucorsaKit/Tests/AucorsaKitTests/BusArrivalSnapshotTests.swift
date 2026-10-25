import Foundation
import Testing
@testable import AucorsaKit

struct BusArrivalSnapshotTests {
    @Test func renamingPreservesEstimatesAndFreshness() throws {
        let original = BusArrivalSnapshot(fetchedAt: 1_800_000_000,
            lines: [.init(lineID: "5", arrivals: [2, 20])])
        let renamed = original.withStopName("Casa 🏡")
        #expect(renamed.stopName == "Casa 🏡")
        #expect(renamed.lines == original.lines)
        #expect(renamed.fetchedAt == original.fetchedAt)
        #expect(renamed.staleDate(endingAt: 1_800_001_000) == original.staleDate(endingAt: 1_800_001_000))
        #expect(try JSONDecoder().decode(BusArrivalSnapshot.self,
            from: JSONEncoder().encode(renamed)) == renamed)
        #expect(original.withStopName(String(repeating: "🏡", count: 100)).stopName?.count == 80)
    }

    @Test func olderActivityContentWithoutANameStillDecodes() throws {
        let data = Data(#"{"fetchedAt":1800000000,"lines":[{"lineID":"5","arrivals":[2,20]}]}"#.utf8)
        let snapshot = try JSONDecoder().decode(BusArrivalSnapshot.self, from: data)
        #expect(snapshot.stopName == nil)
        #expect(snapshot.lines.first?.arrivals == [2, 20])
    }

    @Test func selectedLineStaysPrimaryEvenWhenMissingFromResponse() {
        let snapshot = BusArrivalSnapshot(estimations: [
            .init(lineID: "2", arrivals: [4, 8]), .init(lineID: "3", arrivals: [1]),
            .init(lineID: "4", arrivals: [2])
        ], preferredLineID: "1")
        #expect(snapshot.lines.map(\.lineID) == ["1", "2", "3"])
        #expect(snapshot.lines[0].arrivals.isEmpty)
    }

    @Test func retainsOnlyTwoValidArrivalsPerLine() {
        let line = BusArrivalSnapshot.Line(lineID: "1", arrivals: [-1, 0, 8, 11, 9999])
        #expect(line.arrivals == [0, 8])
    }

    @Test func freshnessExpiresAfter90SecondsOrSessionEnd() {
        let snapshot = BusArrivalSnapshot(fetchedAt: 1_800_000_000, lines: [])
        #expect(snapshot.staleDate(endingAt: 1_800_001_000).timeIntervalSince1970 == 1_800_000_090)
        #expect(snapshot.staleDate(endingAt: 1_800_000_010).timeIntervalSince1970 == 1_800_000_010)
    }

    /// The backend's `snapshot.test` produces this exact file, so a change to
    /// either side's content-state shape fails one of the two suites.
    @Test func decodesTheContentStateTheBackendPushes() throws {
        let url = try #require(Bundle.module.url(forResource: "live_activity_content_state",
                                                 withExtension: "json"))
        let snapshot = try JSONDecoder().decode(BusArrivalSnapshot.self, from: Data(contentsOf: url))
        #expect(snapshot == BusArrivalSnapshot(fetchedAt: 1_800_000_000, lines: [
            .init(lineID: "2", arrivals: [1, 19]), .init(lineID: "1", arrivals: [12, 32])
        ], stopName: "Fátima"))
    }

    @Test func decodingAppliesTheSameLimitsAsTheInitializers() throws {
        let json = #"""
        {"fetchedAt":1800000000,"stopName":"\#(String(repeating: "a", count: 100))","lines":[
          {"lineID":"1","arrivals":[-1,0,8,11]},{"lineID":"2","arrivals":[9999]},
          {"lineID":"3","arrivals":[]},{"lineID":"4","arrivals":[1]}]}
        """#
        let snapshot = try JSONDecoder().decode(BusArrivalSnapshot.self, from: Data(json.utf8))
        #expect(snapshot.lines.map(\.lineID) == ["1", "2", "3"])
        #expect(snapshot.lines.map(\.arrivals) == [[0, 8], [], []])
        #expect(snapshot.stopName?.count == 80)
    }

    @Test func activityContentRoundTripsWithUnixTimestampsAndSmallPayload() throws {
        let snapshot = BusArrivalSnapshot(estimations: [.init(lineID: "2", arrivals: [1, 19])],
            preferredLineID: "2", now: Date(timeIntervalSince1970: 1_800_000_000))
        let data = try JSONEncoder().encode(snapshot)
        #expect(data.count < 1024)
        #expect(try JSONDecoder().decode(BusArrivalSnapshot.self, from: data) == snapshot)
        let json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(json["fetchedAt"] as? Double == 1_800_000_000)
    }
}
