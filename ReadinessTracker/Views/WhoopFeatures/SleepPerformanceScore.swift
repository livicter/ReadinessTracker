import SwiftUI

/// WHOOP-style sleep performance: Need vs Got dual metric + comparative bar,
/// with Efficiency / Consistency as compact one-liners.
struct SleepPerformanceScore: View {
    let sleepNeeded: Double      // Hours needed (14-night average)
    let sleepObtained: Double    // Actual hours slept
    let efficiency: Double       // Sleep efficiency %
    let consistency: Double      // Sleep consistency score 0-100
    var needCaption: String = "14-night average"

    private var performancePercent: Double {
        guard sleepNeeded > 0 else { return 0 }
        return min(100, (sleepObtained / sleepNeeded) * 100)
    }

    private var performanceColor: Color {
        switch performancePercent {
        case 85...100: return RTColor.optimal
        case 70..<85: return RTColor.good
        case 50..<70: return RTColor.caution
        default: return RTColor.warning
        }
    }

    private var performanceLabel: String {
        switch performancePercent {
        case 85...100: return "Optimal"
        case 70..<85: return "Good"
        case 50..<70: return "Fair"
        default: return "Poor"
        }
    }

    private var hourDelta: Double { sleepObtained - sleepNeeded }

    private var scaleMax: Double {
        max(sleepNeeded * 1.25, sleepObtained, 0.1)
    }

    var body: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 14) {
                // Header: title + % ring (morning glance)
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sleep Performance")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(RTColor.primaryText)

                        Text("\(Int(performancePercent))% · \(performanceLabel)")
                            .font(.subheadline)
                            .foregroundStyle(performanceColor)
                    }

                    Spacer()

                    ZStack {
                        Circle()
                            .stroke(RTColor.surfaceHighlight, lineWidth: 6)

                        Circle()
                            .trim(from: 0, to: performancePercent / 100)
                            .stroke(performanceColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                            .rotationEffect(.degrees(-90))

                        Text("\(Int(performancePercent))")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(RTColor.primaryText)
                            .monospacedDigit()
                    }
                    .frame(width: 56, height: 56)
                    .accessibilityLabel("Sleep performance \(Int(performancePercent)) percent")
                }

                // WHOOP-like Need | Got dual metric
                HStack(spacing: 12) {
                    needGotColumn(
                        label: "Need",
                        hours: sleepNeeded,
                        color: RTColor.secondaryText,
                        caption: needCaption
                    )

                    Rectangle()
                        .fill(RTColor.divider)
                        .frame(width: 1)
                        .padding(.vertical, 4)

                    needGotColumn(
                        label: "Got",
                        hours: sleepObtained,
                        color: performanceColor,
                        caption: deltaCaption
                    )
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("sleep.performance.needGot")

                // Comparative bar: actual fill + need marker
                VStack(alignment: .leading, spacing: 6) {
                    GeometryReader { geo in
                        let w = geo.size.width
                        let gotWidth = w * CGFloat(sleepObtained / scaleMax)
                        let needX = w * CGFloat(sleepNeeded / scaleMax)

                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(RTColor.surfaceHighlight)
                                .frame(height: 14)

                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(performanceColor.opacity(0.85))
                                .frame(width: max(4, min(w, gotWidth)), height: 14)

                            // Need marker (vertical tick + white pip)
                            Capsule()
                                .fill(RTColor.primaryText.opacity(0.55))
                                .frame(width: 2, height: 18)
                                .position(x: needX, y: 7)

                            Circle()
                                .fill(.white)
                                .overlay(Circle().stroke(RTColor.primaryText.opacity(0.35), lineWidth: 1))
                                .frame(width: 10, height: 10)
                                .position(x: needX, y: 7)
                        }
                    }
                    .frame(height: 18)
                    .accessibilityLabel(
                        "Got \(String(format: "%.1f", sleepObtained)) hours of \(String(format: "%.1f", sleepNeeded)) needed"
                    )

                    HStack {
                        Text("Need marker")
                            .font(.caption2)
                            .foregroundStyle(RTColor.tertiaryText)
                        Spacer()
                        Text(deltaCaption)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(hourDelta >= 0 ? RTColor.optimal : RTColor.warning)
                            .monospacedDigit()
                    }
                }

                // Efficiency / Consistency one-liners (unchanged role)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    SleepMetricItem(label: "Efficiency", value: "\(Int(efficiency))%", icon: "bolt.fill")
                    SleepMetricItem(label: "Consistency", value: "\(Int(consistency))%", icon: "clock.arrow.circlepath")
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(SurfaceID.sleepPerformance)
        .accessibilityLabel("Sleep Performance")
    }

    private var deltaCaption: String {
        let sign = hourDelta >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", hourDelta))h vs need"
    }

    private func needGotColumn(
        label: String,
        hours: Double,
        color: Color,
        caption: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(RTColor.secondaryText)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(String(format: "%.1f", hours))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
                    .monospacedDigit()
                Text("h")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(RTColor.tertiaryText)
            }

            Text(caption)
                .font(.caption2)
                .foregroundStyle(RTColor.tertiaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label) \(String(format: "%.1f", hours)) hours")
    }
}

private struct SleepMetricItem: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 8) {
            AppIconTile(systemName: icon, color: RTColor.secondaryText, size: 24)
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(RTColor.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .layoutPriority(1)
            Spacer(minLength: 4)
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(RTColor.secondaryText)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: AppleTheme.cornerRadiusMedium, style: .continuous)
                .fill(RTColor.surface)
        )
    }
}
