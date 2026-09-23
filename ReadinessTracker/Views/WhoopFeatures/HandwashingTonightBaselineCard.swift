import SwiftUI
import Charts

/// Elevates HealthKit `handwashingEvent` (total duration minutes) into Tonight | Baseline on
/// Today body after Toothbrushing. Net-new DailyHealthData + HK (#186).
/// Prefer handwashingEvent — mirror toothbrushing duration minutes.
struct HandwashingTonightBaselineCard: View {
    let minutes: Double?
    let history: [(date: Date, minutes: Double)]
    let baseline: Double

    private let softGoal = 1.0

    private var tonight: Double? { minutes.map { max(0, $0) } }

    private var base: Double {
        let b = baseline > 0 ? baseline : (tonight ?? 0)
        return max(0, b)
    }

    private var delta: Double {
        guard let t = tonight else { return 0 }
        return t - base
    }

    private var status: (label: String, color: Color) {
        guard let t = tonight else {
            return ("No reading", RTColor.secondaryText)
        }
        // Hygiene duration vs soft ~2×2 min band + baseline.
        if t >= softGoal { return ("Met", RTColor.optimal) }
        if abs(delta) < 0.5 && t >= softGoal * 0.75 { return ("Steady", RTColor.good) }
        if t >= softGoal * 0.5 { return ("Building", RTColor.caution) }
        if t > 0 { return ("Light", RTColor.caution) }
        return ("Missed", RTColor.warning)
    }

    private var sparklineValues: [Double] {
        Array(history.sorted { $0.date < $1.date }.suffix(7).map(\.minutes))
    }

    private var chartPoints: [(date: Date, value: Double)] {
        history.sorted { $0.date < $1.date }.map { (date: $0.date, value: $0.minutes) }
    }

    private var deltaCaption: String {
        guard tonight != nil else { return "No handwashing logged" }
        let sign = delta >= 0 ? "+" : ""
        return "\(sign)\(formatMin(delta)) vs baseline"
    }

    private let washColor = Color(hex: "5AC8FA")

    var body: some View {
        Group {
            if tonight != nil || !history.isEmpty {
                cardBody
                    .accessibilityIdentifier(SurfaceID.handwashingCard)
            }
        }
    }

    private var cardBody: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Handwashing")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(RTColor.primaryText)

                        Text("Hygiene · \(status.label)")
                            .font(.subheadline)
                            .foregroundStyle(status.color)
                    }

                    Spacer()

                    Text(tonight.map { formatMin($0) } ?? "—")
                        .font(.title2.weight(.bold).monospacedDigit())
                        .foregroundStyle(status.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(status.color.opacity(0.12))
                        .clipShape(Capsule())
                        .accessibilityLabel(
                            tonight.map { "Handwashing \(formatMin($0)) minutes, \(status.label)" }
                                ?? "No handwashing logged"
                        )
                }

                HStack(spacing: 12) {
                    dualColumn(
                        label: "Tonight",
                        valueText: tonight.map { formatMin($0) } ?? "—",
                        unit: "min",
                        color: status.color,
                        caption: "Total duration",
                        icon: "hands.sparkles"
                    )

                    Rectangle()
                        .fill(RTColor.divider)
                        .frame(width: 1)
                        .padding(.vertical, 4)

                    dualColumn(
                        label: "Baseline",
                        valueText: base > 0 ? formatMin(base) : "—",
                        unit: "min",
                        color: RTColor.secondaryText,
                        caption: "7-day avg",
                        icon: "chart.line.uptrend.xyaxis"
                    )
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier(SurfaceID.handwashingBaselineCallout)

                if sparklineValues.count >= 2 {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("7-Day Wash")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(RTColor.secondaryText)
                            Spacer()
                            Text(deltaCaption)
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(abs(delta) < 0.5 ? RTColor.optimal : RTColor.caution)
                                .monospacedDigit()
                        }
                        AnimatedSparkline(data: sparklineValues, color: washColor)
                            .frame(height: 28)
                            .accessibilityIdentifier(SurfaceID.handwashingSpark)
                    }
                }

                if chartPoints.count >= 3 {
                    Chart {
                        ForEach(Array(chartPoints.enumerated()), id: \.offset) { _, point in
                            LineMark(
                                x: .value("Day", point.date),
                                y: .value("min", point.value)
                            )
                            .foregroundStyle(washColor)
                            .interpolationMethod(.catmullRom)

                            AreaMark(
                                x: .value("Day", point.date),
                                y: .value("min", point.value)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [washColor.opacity(0.2), washColor.opacity(0)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .interpolationMethod(.catmullRom)
                        }

                        RuleMark(y: .value("Goal", softGoal))
                            .foregroundStyle(RTColor.secondaryText.opacity(0.35))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    }
                    .chartYScale(domain: yDomain)
                    .chartXAxis(.hidden)
                    .chartYAxis {
                        AxisMarks(position: .leading, values: yMarks) { value in
                            AxisGridLine()
                            AxisValueLabel {
                                if let v = value.as(Double.self) {
                                    Text(formatMin(v))
                                        .font(.caption2)
                                        .foregroundStyle(RTColor.secondaryText)
                                }
                            }
                        }
                    }
                    .frame(height: 88)
                    .accessibilityLabel("Handwashing duration trend last seven days")
                }
            }
            .padding(16)
        }
        .accessibilityIdentifier(SurfaceID.handwashingCard)
    }

    private var yDomain: ClosedRange<Double> {
        let vals = chartPoints.map(\.value) + [base, tonight ?? base, softGoal].filter { $0 >= 0 }
        let lo = max(0.0, (vals.min() ?? 0) - 0.5)
        let hi = max(softGoal * 1.5, (vals.max() ?? softGoal) + 1.0)
        return lo...hi
    }

    private var yMarks: [Double] {
        let mid = ((yDomain.lowerBound + yDomain.upperBound) / 2)
        return [yDomain.lowerBound, mid, yDomain.upperBound]
    }

    private func formatMin(_ v: Double) -> String {
        if abs(v - v.rounded()) < 0.05 { return "\(Int(v.rounded()))" }
        return String(format: "%.1f", v)
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

enum HandwashingBaseline {
    static func average(
        from history: [DailyHealthData],
        window: Int = 7,
        fallback: Double
    ) -> Double {
        let values = history
            .sorted { $0.date > $1.date }
            .prefix(window)
            .compactMap(\.handwashingMinutes)
            .filter { $0 > 0 }
        guard !values.isEmpty else { return fallback }
        return values.reduce(0, +) / Double(values.count)
    }
}
