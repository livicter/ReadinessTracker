import SwiftUI
import Charts

/// WHOOP-style workout duration: Tonight vs Baseline dual callout from
/// `DailyHealthData.workoutMinutes` (feeds StrainCalculator), Active / Moderate /
/// Light / Rest band, and a compact 7-day sparkline.
/// Complements WorkoutSummaryCard’s session list (detail) without re-chroming it;
/// Metrics tiles cover calories/steps more than workout duration.
struct WorkoutMinutesCard: View {
    let currentMinutes: Int
    let history: [(date: Date, minutes: Double)]
    let baseline: Double

    private var tonight: Double { max(0, Double(currentMinutes)) }

    private var base: Double {
        let b = baseline > 0 ? baseline : tonight
        return max(0, b)
    }

    private var deltaMinutes: Double { tonight - base }

    private var status: (label: String, color: Color) {
        // Aligns loosely with StrainCalculator workoutScore (min/30 → up to 6).
        if tonight >= 60 { return ("Active", RTColor.caution) }
        if tonight >= 30 { return ("Moderate", RTColor.good) }
        if tonight >= 15 { return ("Light", RTColor.optimal) }
        return ("Rest", RTColor.secondaryText)
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

    private var strainCaption: String {
        let score = min(6.0, tonight / 30.0)
        return String(format: "%.1f strain pts from duration", score)
    }

    var body: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Workout Minutes")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(RTColor.primaryText)

                        Text("Training duration · \(status.label)")
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
                        .accessibilityLabel("\(Int(tonight.rounded())) workout minutes, \(status.label)")
                }

                HStack(spacing: 12) {
                    dualColumn(
                        label: "Tonight",
                        valueText: "\(Int(tonight.rounded()))",
                        unit: "min",
                        color: status.color,
                        caption: strainCaption,
                        icon: "figure.run"
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
                        caption: "7-day average",
                        icon: "chart.line.flattrend.xyaxis"
                    )
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier(SurfaceID.workoutMinutesBaselineCallout)

                if sparklineValues.count >= 2 {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("7-Day Minutes")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(RTColor.secondaryText)
                            Spacer()
                            Text(deltaCaption)
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(deltaMinutes > 20 ? RTColor.caution : RTColor.optimal)
                                .monospacedDigit()
                        }
                        AnimatedSparkline(data: sparklineValues, color: RTColor.strain)
                            .frame(height: 28)
                            .accessibilityIdentifier(SurfaceID.workoutMinutesSpark)
                    }
                }

                if chartPoints.count >= 3 {
                    Chart {
                        ForEach(Array(chartPoints.enumerated()), id: \.offset) { _, point in
                            LineMark(
                                x: .value("Day", point.date),
                                y: .value("Minutes", point.value)
                            )
                            .foregroundStyle(RTColor.strain)
                            .interpolationMethod(.catmullRom)

                            AreaMark(
                                x: .value("Day", point.date),
                                y: .value("Minutes", point.value)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [RTColor.strain.opacity(0.18), RTColor.strain.opacity(0)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .interpolationMethod(.catmullRom)
                        }

                        RuleMark(y: .value("Moderate", 30))
                            .foregroundStyle(RTColor.secondaryText.opacity(0.35))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    }
                    .chartYScale(domain: 0...(max(75.0, (chartPoints.map(\.value).max() ?? 60) * 1.2)))
                    .chartXAxis(.hidden)
                    .chartYAxis {
                        AxisMarks(position: .leading, values: [15, 30, 60]) { value in
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
                    .accessibilityLabel("Workout minutes trend last days")
                }
            }
            .padding(16)
        }
        .accessibilityIdentifier(SurfaceID.workoutMinutesCard)
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

enum WorkoutMinutes {
    static func baseline(
        from history: [DailyHealthData],
        window: Int = 7,
        fallback: Double
    ) -> Double {
        let values = history
            .sorted { $0.date > $1.date }
            .prefix(window)
            .map { Double($0.workoutMinutes) }
        guard !values.isEmpty else { return fallback }
        return values.reduce(0, +) / Double(values.count)
    }
}
