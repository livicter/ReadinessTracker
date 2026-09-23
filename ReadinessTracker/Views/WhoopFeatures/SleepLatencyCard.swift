import SwiftUI
import Charts

/// WHOOP / Apple Health–style sleep latency: Tonight vs Baseline dual callout,
/// Fast / Typical / Slow band, and a compact 7-night sparkline.
struct SleepLatencyCard: View {
    let currentMinutes: Double
    let history: [(date: Date, minutes: Double)]
    let baseline: Double

    private var tonight: Double { max(0, currentMinutes) }
    private var base: Double {
        let b = baseline > 0 ? baseline : tonight
        return max(0, b)
    }

    private var deltaMinutes: Double { tonight - base }

    private var status: (label: String, color: Color) {
        // Absolute latency first, then vs personal baseline.
        if tonight <= 15 { return ("Fast", RTColor.optimal) }
        if tonight <= 30 { return ("Typical", RTColor.good) }
        if tonight <= 45 { return ("Slow", RTColor.caution) }
        return ("Very Slow", RTColor.warning)
    }

    private var sparklineValues: [Double] {
        let sorted = history.sorted { $0.date < $1.date }
        return Array(sorted.suffix(7).map(\.minutes))
    }

    private var chartPoints: [(date: Date, value: Double)] {
        history.sorted { $0.date < $1.date }.map { (date: $0.date, value: $0.minutes) }
    }

    private var deltaCaption: String {
        let sign = deltaMinutes >= 0 ? "+" : ""
        return "\(sign)\(Int(deltaMinutes.rounded())) min vs baseline"
    }

    var body: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sleep Latency")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(RTColor.primaryText)

                        Text("Time to fall asleep · \(status.label)")
                            .font(.subheadline)
                            .foregroundStyle(status.color)
                    }

                    Spacer()

                    Text("\(Int(tonight.rounded())) min")
                        .font(.title2.weight(.bold).monospacedDigit())
                        .foregroundStyle(status.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(status.color.opacity(0.12))
                        .clipShape(Capsule())
                        .accessibilityLabel("\(Int(tonight.rounded())) minutes to fall asleep, \(status.label)")
                }

                HStack(spacing: 12) {
                    dualColumn(
                        label: "Tonight",
                        valueText: "\(Int(tonight.rounded()))",
                        unit: "min",
                        color: status.color,
                        caption: deltaCaption,
                        icon: "moon.zzz.fill"
                    )

                    Rectangle()
                        .fill(RTColor.divider)
                        .frame(width: 1)
                        .padding(.vertical, 4)

                    dualColumn(
                        label: "Baseline",
                        valueText: "\(Int(base.rounded()))",
                        unit: "min",
                        color: RTColor.secondaryText,
                        caption: "7-night average",
                        icon: "chart.line.flattrend.xyaxis"
                    )
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier(SurfaceID.sleepLatencyBaselineCallout)

                if sparklineValues.count >= 2 {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("7-Night Latency")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(RTColor.secondaryText)
                            Spacer()
                            Text(deltaCaption)
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(deltaMinutes > 8 ? RTColor.warning : RTColor.optimal)
                                .monospacedDigit()
                        }
                        AnimatedSparkline(data: sparklineValues, color: RTColor.sleep)
                            .frame(height: 28)
                            .accessibilityIdentifier(SurfaceID.sleepLatencySpark)
                    }
                }

                if chartPoints.count >= 3 {
                    Chart {
                        ForEach(Array(chartPoints.enumerated()), id: \.offset) { _, point in
                            LineMark(
                                x: .value("Night", point.date),
                                y: .value("Minutes", point.value)
                            )
                            .foregroundStyle(RTColor.sleep)
                            .interpolationMethod(.catmullRom)

                            AreaMark(
                                x: .value("Night", point.date),
                                y: .value("Minutes", point.value)
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

                        RuleMark(y: .value("Typical", 20))
                            .foregroundStyle(RTColor.secondaryText.opacity(0.35))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    }
                    .chartYScale(domain: 0...(max(45, (chartPoints.map(\.value).max() ?? 30) * 1.15)))
                    .chartXAxis(.hidden)
                    .chartYAxis {
                        AxisMarks(position: .leading, values: [0, 15, 30, 45]) { value in
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
                    .accessibilityLabel("Sleep latency trend last nights")
                }
            }
            .padding(16)
        }
        .accessibilityIdentifier(SurfaceID.sleepLatencyCard)
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
