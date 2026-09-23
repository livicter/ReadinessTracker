import SwiftUI
import Charts

/// WHOOP / Apple Health–style sleep efficiency: Tonight vs Baseline dual callout,
/// Excellent / Good / Fair / Poor band, and a compact 7-night sparkline.
struct SleepEfficiencyCard: View {
    /// Efficiency as a fraction 0…1 (same as `DailyHealthData.sleepEfficiency`).
    let currentEfficiency: Double
    let history: [(date: Date, efficiency: Double)]
    let baseline: Double

    private func asPercent(_ value: Double) -> Double {
        // Accept fraction (0.9) or already-percent (90).
        value > 1.5 ? min(100, max(0, value)) : min(100, max(0, value * 100))
    }

    private var tonight: Double { asPercent(currentEfficiency) }

    private var base: Double {
        let b = asPercent(baseline > 0 ? baseline : currentEfficiency)
        return b > 0 ? b : tonight
    }

    private var deltaPoints: Double { tonight - base }

    private var status: (label: String, color: Color) {
        if tonight >= 90 { return ("Excellent", RTColor.optimal) }
        if tonight >= 85 { return ("Good", RTColor.good) }
        if tonight >= 75 { return ("Fair", RTColor.caution) }
        return ("Poor", RTColor.warning)
    }

    private var sparklineValues: [Double] {
        let sorted = history.sorted { $0.date < $1.date }
        return Array(sorted.suffix(7).map { asPercent($0.efficiency) })
    }

    private var chartPoints: [(date: Date, value: Double)] {
        history.sorted { $0.date < $1.date }.map { (date: $0.date, value: asPercent($0.efficiency)) }
    }

    private var deltaCaption: String {
        let sign = deltaPoints >= 0 ? "+" : ""
        return "\(sign)\(Int(deltaPoints.rounded())) pts vs baseline"
    }

    var body: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sleep Efficiency")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(RTColor.primaryText)

                        Text("Asleep ÷ time in bed · \(status.label)")
                            .font(.subheadline)
                            .foregroundStyle(status.color)
                    }

                    Spacer()

                    Text("\(Int(tonight.rounded()))%")
                        .font(.title2.weight(.bold).monospacedDigit())
                        .foregroundStyle(status.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(status.color.opacity(0.12))
                        .clipShape(Capsule())
                        .accessibilityLabel("\(Int(tonight.rounded())) percent sleep efficiency, \(status.label)")
                }

                HStack(spacing: 12) {
                    dualColumn(
                        label: "Tonight",
                        valueText: "\(Int(tonight.rounded()))",
                        unit: "%",
                        color: status.color,
                        caption: deltaCaption,
                        icon: "bolt.fill"
                    )

                    Rectangle()
                        .fill(RTColor.divider)
                        .frame(width: 1)
                        .padding(.vertical, 4)

                    dualColumn(
                        label: "Baseline",
                        valueText: "\(Int(base.rounded()))",
                        unit: "%",
                        color: RTColor.secondaryText,
                        caption: "7-night average",
                        icon: "chart.line.flattrend.xyaxis"
                    )
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier(SurfaceID.sleepEfficiencyBaselineCallout)

                if sparklineValues.count >= 2 {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("7-Night Efficiency")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(RTColor.secondaryText)
                            Spacer()
                            Text(deltaCaption)
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(deltaPoints < -5 ? RTColor.warning : RTColor.optimal)
                                .monospacedDigit()
                        }
                        AnimatedSparkline(data: sparklineValues, color: RTColor.sleep)
                            .frame(height: 28)
                            .accessibilityIdentifier(SurfaceID.sleepEfficiencySpark)
                    }
                }

                if chartPoints.count >= 3 {
                    Chart {
                        ForEach(Array(chartPoints.enumerated()), id: \.offset) { _, point in
                            LineMark(
                                x: .value("Night", point.date),
                                y: .value("Efficiency", point.value)
                            )
                            .foregroundStyle(RTColor.sleep)
                            .interpolationMethod(.catmullRom)

                            AreaMark(
                                x: .value("Night", point.date),
                                y: .value("Efficiency", point.value)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [RTColor.sleep.opacity(0.18), RTColor.sleep.opacity(0)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .interpolationMethod(.catmullRom)
                        }

                        RuleMark(y: .value("Good", 85))
                            .foregroundStyle(RTColor.secondaryText.opacity(0.35))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    }
                    .chartYScale(domain: 60...100)
                    .chartXAxis(.hidden)
                    .chartYAxis {
                        AxisMarks(position: .leading, values: [70, 85, 100]) { value in
                            AxisGridLine()
                            AxisValueLabel {
                                if let v = value.as(Double.self) {
                                    Text("\(Int(v))")
                                        .font(.caption2)
                                        .foregroundStyle(RTColor.secondaryText)
                                }
                            }
                        }
                    }
                    .frame(height: 88)
                    .accessibilityLabel("Sleep efficiency trend last nights")
                }
            }
            .padding(16)
        }
        .accessibilityIdentifier(SurfaceID.sleepEfficiencyCard)
    }

    private func dualColumn(
        label: String,
        valueText: String,
        unit: String,
        color: Color,
        caption: String,
        icon: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(color)
                    .frame(width: 22, height: 22)
                    .background(color.opacity(0.12))
                    .clipShape(Circle())
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
            }
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(valueText)
                    .font(.title2.weight(.bold).monospacedDigit())
                    .foregroundStyle(RTColor.primaryText)
                Text(unit)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(RTColor.secondaryText)
            }
            Text(caption)
                .font(.caption2)
                .foregroundStyle(RTColor.secondaryText)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
