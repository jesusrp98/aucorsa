import AucorsaKit
import SwiftUI
import UIKit

/// Result UI for the arrivals intents.
///
/// Mirrors the line rows of the Flutter stop tile: a coloured badge, the route
/// name, and the arrivals stacked on the trailing edge. The stop itself is not
/// repeated here — Siri already shows it in the dialog — and the view draws no
/// surface of its own, sitting directly on the card Siri provides.
///
/// Every colour is defined here as an explicit light/dark pair rather than
/// taken from the environment. Siri renders snippets on its own card, and the
/// environment's colour scheme does not reliably match that card — relying on
/// `.primary` produced black text on a dark card. Pinning the foregrounds to
/// the appearance we read ourselves makes the contrast ours to guarantee.
struct ArrivalsSnippetView: View {
    struct Row: Identifiable {
        let id: String
        let name: String
        let color: Color
        let arrivals: [Int]
    }

    let rows: [Row]

    var body: some View {
        Group {
            if rows.isEmpty {
                emptyState
            } else {
                VStack(spacing: 12) {
                    ForEach(rows) { row in
                        lineRow(row)
                    }
                }
            }
        }
        // Siri's card leaves the snippet flush with its edges; the bottom is
        // left alone because the card's own button already spaces it.
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }

    private var emptyState: some View {
        HStack(spacing: 8) {
            Image(systemName: "clock.badge.xmark")
            Text("No estimations available", tableName: "Intents")
        }
        .font(Typography.message)
        .foregroundStyle(Palette.onSurfaceVariant)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 4)
    }

    // MARK: - Rows

    private func lineRow(_ row: Row) -> some View {
        HStack(spacing: 12) {
            Text(row.id)
                .font(Typography.badge)
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .padding(4)
                // Letter ids ("O1", "C2") are wider than "3"; a fixed circle
                // keeps the badges aligned down the column.
                .frame(width: 36, height: 36)
                .background(row.color, in: .circle)

            Text(row.name)
                .font(Typography.lineName)
                .foregroundStyle(Palette.onSurface)
                .lineLimit(1)
                // The Flutter tile uses AutoSizeText, which shrinks before it
                // truncates; this approximates that for long route names.
                .minimumScaleFactor(0.75)
                .truncationMode(.tail)

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 2) {
                ForEach(Array(row.arrivals.enumerated()), id: \.offset) { _, minutes in
                    Text(ArrivalsFormatter.arrivalLabel(minutes: minutes))
                        .font(Typography.arrival)
                        .monospacedDigit()
                        .foregroundStyle(
                            minutes == 0 ? Palette.accent : Palette.onSurface
                        )
                }
            }
            .fixedSize(horizontal: true, vertical: false)
        }
    }
}

// MARK: - Typography

/// The Flutter tile's type scale, taken down a quarter.
///
/// Sizes are stated as the Flutter value times `scale` rather than as the
/// arithmetic result, so the relationship to the app stays legible: if a size
/// changes there, the same number changes here.
///
/// The reduction is deliberate. Siri renders the snippet at a text size of its
/// own, noticeably larger than the device's, and it does not honour the
/// device's setting being written into the environment — so the correction is
/// applied to the sizes themselves. `Font.system(size:)` still scales with
/// Dynamic Type, so this stays a quarter below the app at every step of the
/// scale rather than being pinned flat.
private enum Typography {
    private static let scale: CGFloat = 1.0

    /// `ListTile.title` → `bodyLarge` (16, regular).
    static let lineName = Font.system(size: 16 * scale)

    /// The row's `DefaultTextStyle` → `bodyMedium` with `w500` (14, medium).
    static let arrival = Font.system(size: 14 * scale, weight: .medium)

    /// `CircleAvatar`'s label → `titleMedium` (16, medium).
    static let badge = Font.system(size: 16 * scale, weight: .medium)

    /// The empty state's `bodyLarge` (16, regular).
    static let message = Font.system(size: 16 * scale)
}

// MARK: - Palette

/// The app's Material 3 scheme (seeded from `Colors.green`) expressed as
/// light/dark pairs. Hardcoded because the intent process has no access to the
/// Flutter theme, and sampled to match what the app renders.
private enum Palette {
    static let onSurface = dynamic(light: 0x191D17, dark: 0xE2E3DC)
    static let onSurfaceVariant = dynamic(light: 0x43483F, dark: 0xC3C8BC)
    static let accent = dynamic(light: 0x2E6B4F, dark: 0x7FD8A2)

    static func dynamic(light: UInt32, dark: UInt32) -> Color {
        Color(
            uiColor: UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? UIColor(rgb: dark) : UIColor(rgb: light)
            }
        )
    }
}

extension UIColor {
    fileprivate convenience init(rgb: UInt32) {
        self.init(
            red: CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8) & 0xFF) / 255,
            blue: CGFloat(rgb & 0xFF) / 255,
            alpha: 1
        )
    }
}

// MARK: - Building from catalog data

extension ArrivalsSnippetView {
    init(
        estimations: [BusStopLineEstimation],
        catalog: TransitCatalog = .shared
    ) {
        let rows = estimations.compactMap { estimation -> Row? in
            // Drop lines the catalog does not know, matching the Flutter tile's
            // `isLineAvailable` filter.
            guard
                !estimation.arrivals.isEmpty,
                let line = catalog.line(id: estimation.lineID)
            else { return nil }

            return Row(
                id: line.id,
                name: line.name,
                color: Self.badgeColor(for: line),
                arrivals: estimation.arrivals
            )
        }

        self.init(rows: rows)
    }

    /// Mirrors `BusLineTile.resolveLineBackgroundColor`: line colours are tuned
    /// for a light background, so dark mode darkens them 24% toward black.
    static func badgeColor(for line: BusLine) -> Color {
        Color(
            uiColor: UIColor { traits in
                let factor: CGFloat = traits.userInterfaceStyle == .dark ? 0.76 : 1

                return UIColor(
                    red: CGFloat(line.red) * factor,
                    green: CGFloat(line.green) * factor,
                    blue: CGFloat(line.blue) * factor,
                    alpha: 1
                )
            }
        )
    }
}

// MARK: - Previews

//#if DEBUG

/// Sample data for the canvas.
///
/// Rows are built by hand rather than through the catalog so the previews render
/// identically whether or not `transit_data.json` resolves in the preview
/// process. `PreviewSamples.fromCatalog` covers the real lookup path separately.
enum PreviewSamples {
    /// Real ids, names and colours, copied from the generated catalog.
    static func row(_ id: String, _ name: String, _ hex: UInt32, _ arrivals: [Int])
        -> ArrivalsSnippetView.Row
    {
        ArrivalsSnippetView.Row(
            id: id,
            name: name,
            color: ArrivalsSnippetView.badgeColor(
                for: BusLine(id: id, name: name, colorValue: hex, stops: [])
            ),
            arrivals: arrivals
        )
    }

    static let line3 = row("3", "Albaida - Renfe - Fuensanta", 0x9A65A4, [13, 38])
    static let lineT = row("T", "Córdoba - Trasierra", 0xA1D9F3, [71])
    static let line5 = row("5", "C. Sanitaria - Renfe - Valdeolleros", 0x01498B, [22, 44])
    static let lineO1 = row("O1", "Córdoba - Villarrubia - Veredón", 0xFFEC00, [0, 94])
    static let lineC2 = row("C2", "Tendillas - Padres de Gracia", 0xF09271, [4])
    static let line1 = row("1", "Fátima - Tendillas", 0x166C4B, [2, 17, 33])
    static let line12 = row("12", "Naranjo - Tendillas - Sector Sur", 0x65B147, [9])
    static let lineN = row("N", "Córdoba - Cerro Muriano", 0xA2CD98, [55])
}

/// Wraps a snippet the way Siri does: on a card over an opaque backdrop. The
/// view no longer paints its own surface, so this stage supplies the card —
/// which is what makes the previews useful for spotting contrast problems, the
/// way the original black-text-on-dark-card bug slipped through.
private struct SnippetStage<Content: View>: View {
    let scheme: ColorScheme
    @ViewBuilder var content: Content

    var body: some View {
        content
            // No inset of its own: the snippet now carries its own padding, and
            // doubling it here would hide how it really sits on Siri's card.
            .padding(.bottom, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(scheme == .dark ? Color(white: 0.11) : Color(white: 0.96))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(scheme == .dark ? Color.black : Color(white: 0.85))
            .environment(\.colorScheme, scheme)
    }
}

#Preview("Typical stop") {
    SnippetStage(scheme: .dark) {
        ArrivalsSnippetView(rows: [PreviewSamples.line3, PreviewSamples.lineT])
    }
}

#Preview("Typical stop · light") {
    SnippetStage(scheme: .light) {
        ArrivalsSnippetView(rows: [PreviewSamples.line3, PreviewSamples.lineT])
    }
}

/// A bus already at the stop shows "Now" in the accent colour.
#Preview("Arriving now") {
    SnippetStage(scheme: .dark) {
        ArrivalsSnippetView(rows: [PreviewSamples.line5, PreviewSamples.lineO1])
    }
}

#Preview("Single line") {
    SnippetStage(scheme: .dark) {
        ArrivalsSnippetView(rows: [PreviewSamples.lineC2])
    }
}

/// Roughly one stop in six returns "Sin estimaciones" upstream, so this is a
/// routine state rather than an error.
#Preview("No estimations") {
    SnippetStage(scheme: .dark) {
        ArrivalsSnippetView(rows: [])
    }
}

#Preview("No estimations · light") {
    SnippetStage(scheme: .light) {
        ArrivalsSnippetView(rows: [])
    }
}

/// Busy interchange. Snippets are height-capped and do not scroll, so this is
/// the preview to watch for clipping.
#Preview("Busy stop") {
    SnippetStage(scheme: .dark) {
        ArrivalsSnippetView(rows: [
            PreviewSamples.line1, PreviewSamples.line3, PreviewSamples.line5,
            PreviewSamples.line12, PreviewSamples.lineC2, PreviewSamples.lineN,
            PreviewSamples.lineO1, PreviewSamples.lineT
        ])
    }
}

/// Worst case for horizontal space: long route names and a two-character line
/// id.
#Preview("Long names") {
    SnippetStage(scheme: .dark) {
        ArrivalsSnippetView(rows: [PreviewSamples.line5, PreviewSamples.lineO1])
    }
}

/// Exercises the real path: catalog lookup for names and colours. Renders empty
/// if the bundled catalog does not resolve in the preview process — which is
/// itself worth knowing.
#Preview("From catalog") {
    SnippetStage(scheme: .dark) {
        ArrivalsSnippetView(
            estimations: [
                BusStopLineEstimation(lineID: "1", arrivals: [3, 21]),
                BusStopLineEstimation(lineID: "2", arrivals: [14, 34])
            ]
        )
    }
}

/// Dynamic Type at an accessibility size, where the row layout is most likely
/// to break.
#Preview("Large text") {
    SnippetStage(scheme: .dark) {
        ArrivalsSnippetView(rows: [PreviewSamples.line3, PreviewSamples.lineT])
    }
    .environment(\.dynamicTypeSize, .accessibility1)
}

//#endif
