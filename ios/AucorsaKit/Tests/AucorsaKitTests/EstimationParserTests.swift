import Foundation
import Testing

@testable import AucorsaKit

/// The parser reads markup AUCORSA can change without warning, so these run
/// against fragments captured from the live endpoint. If AUCORSA reshapes its
/// HTML, these fail rather than Siri silently reporting no buses.
@Suite("Estimation parser")
struct EstimationParserTests {
    static func fixture(_ name: String) throws -> String {
        let url = try #require(
            Bundle.module.url(forResource: name, withExtension: "html"),
            "missing fixture \(name).html"
        )
        return try String(contentsOf: url, encoding: .utf8)
    }

    @Test("Parses a stop served by two lines")
    func populatedStop() throws {
        let estimations = EstimationParser.parse(try Self.fixture("estimations_populated"))

        #expect(estimations.count == 2)

        let lineIDs = estimations.map(\.lineID)
        #expect(lineIDs.contains("2"))
        #expect(lineIDs.contains("1"))

        for estimation in estimations {
            #expect(!estimation.arrivals.isEmpty)
            #expect(estimation.arrivals.allSatisfy { $0 >= 0 && $0 < 300 })
        }

        // The captured fixture had two estimates per line.
        #expect(estimations.allSatisfy { $0.arrivals.count == 2 })
    }

    @Test("A stop with no service parses to an empty result, not an error")
    func emptyStop() throws {
        let html = try Self.fixture("estimations_empty")
        #expect(html.contains("ppp-no-estimations"))
        #expect(EstimationParser.parse(html).isEmpty)
    }

    @Test("Garbage input yields nothing rather than throwing")
    func garbageInput() {
        #expect(EstimationParser.parse("").isEmpty)
        #expect(EstimationParser.parse("<html><body>nope</body></html>").isEmpty)
    }

    @Test(
        "Minute extraction matches the Dart leading-digits rule",
        arguments: [
            ("3 minutos", 3),
            ("1 minuto", 1),
            ("21 minutos", 21),
            ("  7 minutos", 7)
        ]
    )
    func minuteParsing(input: String, expected: Int) {
        #expect(EstimationParser.minutes(from: input) == expected)
    }

    @Test("Non-numeric estimates are dropped, not reported as zero")
    func nonNumericEstimate() {
        #expect(EstimationParser.minutes(from: "En parada") == nil)
        #expect(EstimationParser.minutes(from: "") == nil)
    }

    @Test("Letter line ids survive parsing")
    func letterLineIDs() {
        // O1/O2/C2/E/N all appear in live responses.
        let html = """
        <div class="ppp-container"><div class="ppp-line-number" style="x">O1</div>\
        <div class="ppp-estimation"><span>Pr&oacute;ximo: <strong>4 minutos</strong></span></div></div>
        """
        let parsed = EstimationParser.parse(html)
        #expect(parsed.count == 1)
        #expect(parsed.first?.lineID == "O1")
        #expect(parsed.first?.arrivals == [4])
    }

    @Test("HTML entities decode")
    func entityDecoding() {
        #expect(EstimationParser.decodeEntities("Pr&oacute;ximo") == "Próximo")
        #expect(EstimationParser.decodeEntities("A&ntilde;adir") == "Añadir")
        #expect(EstimationParser.decodeEntities("plain") == "plain")
    }
}
