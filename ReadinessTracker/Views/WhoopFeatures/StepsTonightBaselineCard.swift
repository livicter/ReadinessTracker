import SwiftUI
import Charts

/// Elevates Body `steps` into a Tonight | Baseline dual on Today Body.
/// Body tile remains the glance chip; Metrics stay calories-heavy — this is the
/// daily dual-callout without re-chroming the tile well.
struct StepsTonightBaselineCard: View {
    let currentSteps: Int
    let history: [(date: Date, steps: Double)]
    let baseline: Double

    private let goal: Double = 10_000

    private var tonight: Double { max(0, Double(currentSteps)) }

    private var base: Double {
        let b = baseline > 0 ? baseline : tonight
        return max(0, b)
    }

    private var delta: Double { tonight - base }

    private var goalFraction: Double {
        min(1.2, tonight / goal)
    }

    private var status: (label: String, color: Color) {
        if tonight >= goal { return ("Goal hit", RTColor.optimal) }
        if tonight >= goal * 0.75 { return ("On track", RTColor.good) }
        if tonight >= goal * 0.40 { return ("Building", RTColor.caution) }
        return ("Low", RTColor.warning)
    }

    private var sparklineValues: [Double] {
        let sorted = history.sorted { $0.date < $1.date }
        return Array(sorted.suffix(7).map(\.steps))
    }

    private var chartPoints: [(date: Date, value: Double)] {
        history.sorted { $0.date < $1.date }.map { (date: $0.date, value: $0.steps) }
    }

    private var deltaCaption: String {
        let sign = delta >= 0 ? "+" : ""
        return "\(sign)\(formatted(delta)) vs baseline"
    }

    private var goalCaption: String {
        "\(Int((goalFraction * 100).rounded()))% of 10k"
    }

    private func formatted(_ value: Double) -> String {
        let n = Int(value.rounded())
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return f.string(from: NSNumber(value: n)) ?? "\(n)"
    }

    var body: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Steps")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(RTColor.primaryText)

                        Text("Daily movement · \(status.label)")
                            .font(.subheadline)
                            .foregroundStyle(status.color)
                    }

                    Spacer()

                    Text(formatted(tonight))
                        .font(.title2.weight(.bold).monospacedDigit())
                        .foregroundStyle(status.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(status.color.opacity(0.12))
                        .clipShape(Capsule())
                        .accessibilityLabel("\(formatted(tonight)) steps, \(status.label)")
                }

                HStack(spacing: 12) {
                    dualColumn(
                        label: "Tonight",
                        valueText: formatted(tonight),
                        unit: "steps",
                        color: status.color,
                        caption: goalCaption,
                        icon: "figure.walk"
                    )

                    Rectangle()
                        .fill(RTColor.divider)
                        .frame(width: 1)
                        .padding(.vertical, 4)

                    dualColumn(
                        label: "Baseline",
                        valueText: formatted(base),
                        unit: "steps",
                        color: RTColor.secondaryText,
                        caption: "7-day average",
                        icon: "chart.line.flattrend.xyaxis"
                    )
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier(SurfaceID.stepsBaselineCallout)

                if sparklineValues.count >= 2 {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("7-Day Steps")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(RTColor.secondaryText)
                            Spacer()
                            Text(deltaCaption)
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(delta < -1500 ? RTColor.caution : RTColor.optimal)
                                .monospacedDigit()
                        }
                        AnimatedSparkline(data: sparklineValues, color: RTColor.optimal)
                            .frame(height: 28)
                            .accessibilityIdentifier(SurfaceID.stepsSpark)
                    }
                }

                if chartPoints.count >= 3 {
                    Chart {
                        ForEach(Array(chartPoints.enumerated()), id: \.offset) { _, point in
                            LineMark(
                                x: .value("Day", point.date),
                                y: .value("Steps", point.value)
                            )
                            .foregroundStyle(RTColor.optimal)
                            .interpolationMethod(.catmullRom)

                            AreaMark(
                                x: .value("Day", point.date),
                                y: .value("Steps", point.value)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [RTColor.optimal.opacity(0.18), RTColor.optimal.opacity(0)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .interpolationMethod(.catmullRom)
                        }

                        RuleMark(y: .value("Goal", goal))
                            .foregroundStyle(RTColor.secondaryText.opacity(0.35))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    }
                    .chartYScale(domain: 0...(max(goal * 1.15, (chartPoints.map(\.value).max() ?? goal) * 1.15)))
                    .chartXAxis(.hidden)
                    .chartYAxis {
                        AxisMarks(position: .leading, values: [5000, 10000]) { value in
                            AxisGridLine()
                            AxisValueLabel {
                                if let v = value.as(Double.self) {
                                    Text(v >= 10000 ? "10k" : "5k")
                                        .font(.caption2)
                                        .foregroundStyle(RTColor.secondaryText)
                                }
                            }
                        }
                    }
                    .frame(height: 88)
                    .accessibilityLabel("Steps trend last seven days")
                }
            }
            .padding(16)
        }
        .accessibilityIdentifier(SurfaceID.stepsCard)
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

enum StepsBaseline {
    static func average(
        from history: [DailyHealthData],
        window: Int = 7,
        fallback: Double
    ) -> Double {
        let values = history
            .sorted { $0.date > $1.date }
            .prefix(window)
            .map { Double($0.steps) }
            .filter { $0 >= 0 }
        guard !values.isEmpty else { return fallback }
        return values.reduce(0, +) / Double(values.count)
    }
}
