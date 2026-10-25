import ActivityKit
import AucorsaKit
import SwiftUI
import WidgetKit

@main
struct AucorsaLiveActivityBundle: WidgetBundle {
    var body: some Widget { BusArrivalLiveActivity() }
}

struct BusArrivalLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: BusArrivalAttributes.self) { context in
            ArrivalCard(context: context)
                .padding(14)
                .activityBackgroundTint(Color(red: 0.06, green: 0.08, blue: 0.10))
                .activitySystemActionForegroundColor(.white)
                .widgetURL(context.attributes.url)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    LineBadge(lineID: context.attributes.preferredLineID)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    ArrivalEstimate(context: context)
                        .font(.title2.bold())
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ArrivalDetails(context: context)
                }
            } compactLeading: {
                LineBadge(lineID: context.attributes.preferredLineID, compact: true)
            } compactTrailing: {
                ArrivalEstimate(context: context)
                    .font(.system(.caption, design: .rounded, weight: .semibold))
            } minimal: {
                if context.isStale {
                    Image(systemName: "arrow.clockwise")
                        .foregroundStyle(.orange)
                        .accessibilityLabel(context.attributes.isSpanish ? "Actualizar estimaciones" : "Refresh arrivals")
                } else {
                    ArrivalEstimate(context: context, minimal: true)
                        .font(.system(.caption2, design: .rounded, weight: .bold))
                }
            }
            // Keep the badge and text inside the Island's curved edges.
            .contentMargins(.horizontal, 24, for: .expanded)
            .contentMargins([.top, .bottom], 20, for: .expanded)
            .widgetURL(context.attributes.url)
            .keylineTint(.cyan)
        }
    }
}

private struct LineBadge: View {
    let lineID: String
    var compact = false

    private var color: Color {
        guard let line = TransitCatalog.shared.line(id: lineID) else { return .blue }
        return Color(red: line.red, green: line.green, blue: line.blue)
    }

    var body: some View {
        Text(lineID)
            .font(.system(compact ? .caption : .headline, design: .rounded, weight: .bold))
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .padding(compact ? 3 : 4)
            .frame(width: compact ? 24 : 32, height: compact ? 24 : 32)
            .background(color.gradient, in: Circle())
            .foregroundStyle(.white)
            .accessibilityLabel("\(lineID)")
    }
}

private struct ArrivalEstimate: View {
    let context: ActivityViewContext<BusArrivalAttributes>
    var minimal = false

    var body: some View {
        Group {
            if context.isStale {
                Text("—").foregroundStyle(.orange)
            } else if let minutes = context.state.lines.first?.arrivals.first {
                if minutes == 0 {
                    ArrivingNow(spanish: context.attributes.isSpanish, fetchedAt: context.state.fetchedAt)
                } else {
                    Text(minimal ? "\(minutes)m" : "\(minutes) min")
                }
            } else {
                Text("—").foregroundStyle(.secondary)
            }
        }
        .monospacedDigit()
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .accessibilityLabel(context.isStale
            ? (context.attributes.isSpanish ? "Estimaciones sin actualizar" : "Arrivals out of date")
            : (context.state.lines.first?.arrivals.first.map {
                $0 == 0
                    ? (context.attributes.isSpanish ? "Ahora" : "Now")
                    : (context.attributes.isSpanish ? "\($0) minutos estimados" : "\($0) minutes estimated")
            } ?? (context.attributes.isSpanish ? "Sin estimaciones" : "No estimates")))
    }
}

private enum ArrivalStyle {
    // A light green remains legible on the Island's black background.
    static let now = Color(red: 0.60, green: 0.84, blue: 0.49)
}

private struct ArrivingNow: View {
    let spanish: Bool
    let fetchedAt: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced

    var body: some View {
        // Live Activities animate content updates, not continuous state-driven
        // loops. Each new estimate gently fades Now back to full brightness.
        ZStack {
            Text(spanish ? "Ahora" : "Now")
                .foregroundStyle(ArrivalStyle.now)
                .id(fetchedAt)
                .transition(reduceMotion || isLuminanceReduced ? .identity : .asymmetric(
                    insertion: .modifier(
                        active: ArrivalPulse(opacity: 0.32),
                        identity: ArrivalPulse(opacity: 1)
                    ),
                    removal: .identity
                ))
        }
        .animation(reduceMotion || isLuminanceReduced ? nil : .easeInOut(duration: 0.7), value: fetchedAt)
    }
}

private struct ArrivalPulse: ViewModifier {
    let opacity: Double

    func body(content: Content) -> some View {
        content.opacity(opacity)
    }
}

/// The Lock Screen card: the expanded Island's layout, without its curved edges.
private struct ArrivalCard: View {
    let context: ActivityViewContext<BusArrivalAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                LineBadge(lineID: context.attributes.preferredLineID)
                Spacer(minLength: 8)
                ArrivalEstimate(context: context).font(.title2.bold())
            }
            ArrivalDetails(context: context)
        }
        .foregroundStyle(.white)
    }
}

/// Shared by the expanded Island and the Lock Screen.
private struct ArrivalDetails: View {
    let context: ActivityViewContext<BusArrivalAttributes>
    private var spanish: Bool { context.attributes.isSpanish }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(context.state.stopName ?? context.attributes.stopName)
                .font(.headline)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .fixedSize(horizontal: false, vertical: true)
            if context.isStale {
                Text(spanish ? "Abre Aucorsa para actualizar las llegadas" : "Open Aucorsa to refresh arrivals")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .lineLimit(2)
            }
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                nextArrival
                Spacer(minLength: 0)
                lastUpdatedInline
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .frame(maxWidth: .infinity)
        }
    }

    private var nextArrival: Text {
        if context.isStale {
            return Text(spanish ? "Siguiente: —" : "Next: —")
        }
        guard let minutes = context.state.lines.first?.arrivals.dropFirst().first else {
            return Text(spanish ? "Siguiente: —" : "Next: —")
        }
        return Text(arrivalSentence(prefix: spanish ? "Siguiente" : "Next", minutes: minutes))
    }

    private var lastUpdatedInline: Text {
        let date = Date(timeIntervalSince1970: context.state.fetchedAt)
        return Text(spanish ? "Actualizado " : "Last updated ")
            + Text(date, format: .dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits))
    }

    private func arrivalSentence(prefix: String, minutes: Int) -> AttributedString {
        if minutes == 0 {
            var now = AttributedString(spanish ? "ahora" : "now")
            now.foregroundColor = ArrivalStyle.now
            return AttributedString("\(prefix) ") + now
        }
        return AttributedString("\(prefix) \(spanish ? "en" : "in") \(minutes) min")
    }
}
