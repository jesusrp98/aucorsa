import Foundation
import RegexBuilder

/// Parses the HTML fragment the estimations endpoint returns.
///
/// Port of `BusStopLineEstimation.fromHtml` in
/// `lib/common/models/bus_stop_line_estimation.dart`. Like the Dart original it
/// is tied to the exact markup AUCORSA emits, which is the most fragile part of
/// this package -- `EstimationParserTests` runs it against captured fixtures so
/// a markup change fails the tests rather than Siri.
///
/// Observed shape (one block per line serving the stop):
/// ```html
/// <div class="ppp-container">
///   <div class="ppp-line-number" style="...">2</div>
///   ...
///   <div class="ppp-estimation">...<strong>3 minutos</strong>...</div>
///   <div class="ppp-estimation">...<strong>21 minutos</strong>...</div>
/// </div>
/// ```
/// A stop with no service returns `<div class="ppp-no-estimations">` and no
/// containers at all. That is a normal state, not a failure.
public enum EstimationParser {
    private static let containerSeparator = #"<div class="ppp-container">"#

    private static let lineNumberPattern = try! NSRegularExpression(
        pattern: #"class="ppp-line-number"[^>]*>(.*?)</div>"#,
        options: [.dotMatchesLineSeparators]
    )

    private static let arrivalPattern = try! NSRegularExpression(
        pattern: #"<strong>(.*?)</strong>"#,
        options: [.dotMatchesLineSeparators]
    )

    /// Leading digits, matching the Dart `RegExp('^([0-9]*)')`.
    private static let minutesPattern = try! NSRegularExpression(
        pattern: #"^\s*([0-9]+)"#
    )

    public static func parse(_ html: String) -> [BusStopLineEstimation] {
        // Splitting on the container marker is more robust than trying to match
        // balanced <div>s, and the marker never appears in stop or line names.
        let blocks = html.components(separatedBy: containerSeparator).dropFirst()

        return blocks.compactMap { block -> BusStopLineEstimation? in
            guard let lineID = firstMatch(lineNumberPattern, in: block) else {
                return nil
            }

            let trimmedID = decodeEntities(lineID).trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            guard !trimmedID.isEmpty else { return nil }

            let arrivals = allMatches(arrivalPattern, in: block).compactMap(minutes(from:))

            return BusStopLineEstimation(lineID: trimmedID, arrivals: arrivals)
        }
    }

    /// `"3 minutos"` -> `3`, `"1 minuto"` -> `1`.
    ///
    /// The Dart original falls back to zero when the leading number is missing;
    /// this drops the entry instead. A bus "arriving in 0 minutes" is a worse
    /// answer for Siri to speak than one estimate fewer.
    static func minutes(from text: String) -> Int? {
        let decoded = decodeEntities(text)
        guard let match = firstMatch(minutesPattern, in: decoded) else { return nil }
        return Int(match)
    }

    // MARK: - Helpers

    private static func firstMatch(
        _ regex: NSRegularExpression, in value: String
    ) -> String? {
        allMatches(regex, in: value).first
    }

    private static func allMatches(
        _ regex: NSRegularExpression, in value: String
    ) -> [String] {
        let range = NSRange(value.startIndex..., in: value)

        return regex.matches(in: value, range: range).compactMap { match in
            guard
                match.numberOfRanges > 1,
                let captured = Range(match.range(at: 1), in: value)
            else { return nil }

            return String(value[captured])
        }
    }

    /// The markup carries HTML entities (`Pr&oacute;ximo`, `&ntilde;`). Line ids
    /// are plain today, but decoding keeps a future accented id from breaking
    /// the match against the catalog.
    static func decodeEntities(_ value: String) -> String {
        guard value.contains("&") else { return value }

        var result = value
        let entities = [
            ("&amp;", "&"), ("&lt;", "<"), ("&gt;", ">"), ("&quot;", "\""),
            ("&#039;", "'"), ("&apos;", "'"), ("&nbsp;", " "),
            ("&aacute;", "á"), ("&eacute;", "é"), ("&iacute;", "í"),
            ("&oacute;", "ó"), ("&uacute;", "ú"), ("&ntilde;", "ñ"),
            ("&Aacute;", "Á"), ("&Eacute;", "É"), ("&Iacute;", "Í"),
            ("&Oacute;", "Ó"), ("&Uacute;", "Ú"), ("&Ntilde;", "Ñ")
        ]
        for (entity, replacement) in entities {
            result = result.replacingOccurrences(of: entity, with: replacement)
        }
        return result
    }
}
