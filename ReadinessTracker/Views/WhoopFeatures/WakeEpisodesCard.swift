import SwiftUI
import Charts

/// WHOOP / Apple Health–style wake episodes: Tonight vs Baseline dual callout,
/// Calm / Typical / Restless / Disrupted band, and a compact 7-night sparkline.
/// Elevates the buried Sleep Analysis “Wake Episodes” timing chip + Today disturbance cue.
struct WakeEpisodesCard: View {
    let currentCount: Int
    let history: [(date: Date, count: Double)]
    let baseline: Double

    private var tonight: Double { max(0, Double(currentCount)) }
    private var base: Double {
        let b = baseline > 0 ? baseline : tonight
        return max(0, b)
    }

    private var deltaCount: Double { tonight - base }

    private var status: (label: String, color: Color) {
        // Absolute wakes first (lower is better), then vs personal baseline.
        if tonight <= 1 { return ("Calm", RTColor.optimal) }
        if tonight <= 2 { return ("Typical", RTColor.good) }
        if tonight <= 4 { return ("Restless", RTColor.caution) }
        return ("Disrupted", RTColor.warning)
    }

    private var sparklineValues: [Double] {
        let sorted = history.sorted { $0.date < $1.date }
        return Array(sorted.suffix(7).map(\.count))
    }

    private var chartPoints: [(date: Date, value: Double)] {
        history.sorted { $0.date < $1.date }.map { (date: $0.date, value: $0.count) }
    }

    private var deltaCaption: String {
        let sign = deltaCount >= 0 ? "+" : ""
        return "\(sign)\(Int(deltaCount.rounded())) vs baseline"
    }

    var body: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Wake Episodes")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(RTColor.primaryText)

                        Text("Mid-sleep awakenings · \(status.label)")
                            .font(.subheadline)
                            .foregroundStyle(status.color)
                    }

                    Spacer()

                    Text("\(Int(tonight.rounded()))")
                        .font(.title2.weight(.bold).monospacedDigit())
                        .foregroundStyle(status.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(status.color.opacity(0.12))
                        .clipShape(Capsule())
                        .accessibilityLabel("\(Int(tonight.rounded())) wake episodes, \(status.label)")
                }

                HStack(spacing: 12) {
                    dualColumn(
                        label: "Tonight",
                        valueText: "\(Int(tonight.rounded()))",
                        unit: tonight == 1 ? "wake" : "wakes",
                        color: status.color,
                        caption: deltaCaption,
                        icon: "eye.fill"
                    )

                    Rectangle()
                        .fill(RTColor.divider)
                        .frame(width: 1)
                        .padding(.vertical, 4)

                    dualColumn(
                        label: "Baseline",
                        valueText: String(format: "%.1f", base),
                        unit: "avg",
                        color: RTColor.secondaryText,
                        caption: "7-night average",
                        icon: "chart.line.flattrend.xyaxis"
                    )
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier(SurfaceID.wakeEpisodesBaselineCallout)

                if sparklineValues.count >= 2 {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("7-Night Wakes")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(RTColor.secondaryText)
                            Spacer()
                            Text(deltaCaption)
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(deltaCount > 1 ? RTColor.warning : RTColor.optimal)
                                .monospacedDigit()
                        }
                        AnimatedSparkline(data: sparklineValues, color: RTColor.sleep)
                            .frame(height: 28)
                            .accessibilityIdentifier(SurfaceID.wakeEpisodesSpark)
                    }
                }

                if chartPoints.count >= 3 {
                    Chart {
                        ForEach(Array(chartPoints.enumerated()), id: \.offset) { _, point in
                            LineMark(
                                x: .value("Night", point.date),
                                y: .value("Wakes", point.value)
                            )
                            .foregroundStyle(RTColor.sleep)
                            .interpolationMethod(.catmullRom)

                            AreaMark(
                                x: .value("Night", point.date),
                                y: .value("Wakes", point.value)
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

                        RuleMark(y: .value("Typical", 2))
                            .foregroundStyle(RTColor.secondaryText.opacity(0.35))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    }
                    .chartYScale(domain: 0...(max(5, (chartPoints.map(\.value).max() ?? 3) + 1)))
                    .chartXAxis(.hidden)
                    .chartYAxis {
                        AxisMarks(position: .leading, values: [0, 1, 2, 3, 4]) { value in
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
                    .accessibilityLabel("Wake episodes trend last nights")
                }
            }
            .padding(16)
        }
        .accessibilityIdentifier(SurfaceID.wakeEpisodesCard)
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
