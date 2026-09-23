import SwiftUI
import Charts

/// Elevates `nutrition.biotinMcg` (HK `dietaryBiotin`) into Tonight | Baseline
/// on Today Body after Pantothenic Acid. Net-new NutritionSummary + HK (#210).
/// Prefer dietaryBiotin — last clear leftover B-vitamin. Higher is better (soft 30 mcg).
struct DietaryBiotinTonightBaselineCard: View {
    let biotinMcg: Double?
    let history: [(date: Date, mcg: Double)]
    let baselineMcg: Double

    private let softGoal = 30.0
    private let buildingFloor = 20.0

    private var tonight: Double { max(0, biotinMcg ?? 0) }

    private var base: Double {
        let b = baselineMcg > 0 ? baselineMcg : tonight
        return max(0, b)
    }

    private var delta: Double { tonight - base }

    private var status: (label: String, color: Color) {
        if biotinMcg == nil { return ("No reading", RTColor.secondaryText) }
        // Higher biotin is generally favorable (soft ~30 mcg goal).
        if tonight >= softGoal { return ("Met", RTColor.optimal) }
        if tonight >= buildingFloor { return ("Building", RTColor.good) }
        if tonight >= softGoal * 0.4 { return ("Low", RTColor.caution) }
        return ("Very low", RTColor.warning)
    }

    private var sparklineValues: [Double] {
        Array(history.sorted { $0.date < $1.date }.suffix(7).map(\.mcg))
    }

    private var chartPoints: [(date: Date, value: Double)] {
        history.sorted { $0.date < $1.date }.map { (date: $0.date, value: $0.mcg) }
    }

    private var deltaCaption: String {
        guard biotinMcg != nil else { return "No dietary biotin logged" }
        let sign = delta >= 0 ? "+" : ""
        return "\(sign)\(formatMcg(abs(delta))) mcg vs baseline"
    }

    private var limitCaption: String {
        "\(Int((min(1.2, tonight / softGoal) * 100).rounded()))% of \(Int(softGoal)) mcg goal"
    }

    private let biotinColor = Color(hex: "BF5AF2")

    var body: some View {
        Group {
            if biotinMcg != nil {
                cardBody
            }
        }
    }

    private var cardBody: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Dietary Biotin")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(RTColor.primaryText)

                        Text("Intake · \(status.label)")
                            .font(.subheadline)
                            .foregroundStyle(status.color)
                    }

                    Spacer()

                    Text(formatMcg(tonight))
                        .font(.title2.weight(.bold).monospacedDigit())
                        .foregroundStyle(status.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(status.color.opacity(0.12))
                        .clipShape(Capsule())
                        .accessibilityLabel("\(formatMcg(tonight)) micrograms dietary biotin, \(status.label)")
                }

                HStack(spacing: 12) {
                    dualColumn(
                        label: "Tonight",
                        valueText: formatMcg(tonight),
                        unit: "mcg",
                        color: status.color,
                        caption: limitCaption,
                        icon: "sparkles"
                    )

                    Rectangle()
                        .fill(RTColor.divider)
                        .frame(width: 1)
                        .padding(.vertical, 4)

                    dualColumn(
                        label: "Baseline",
                        valueText: base > 0 ? formatMcg(base) : "—",
                        unit: "mcg",
                        color: RTColor.secondaryText,
                        caption: "7-day avg",
                        icon: "chart.line.uptrend.xyaxis"
                    )
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier(SurfaceID.dietaryBiotinBaselineCallout)

                if sparklineValues.count >= 2 {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("7-Day Dietary Biotin")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(RTColor.secondaryText)
                            Spacer()
                            Text(deltaCaption)
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(delta >= 0 ? RTColor.optimal : RTColor.caution)
                                .monospacedDigit()
                        }
                        AnimatedSparkline(data: sparklineValues, color: biotinColor)
                            .frame(height: 28)
                            .accessibilityIdentifier(SurfaceID.dietaryBiotinSpark)
                    }
                }

                if chartPoints.count >= 3 {
                    Chart {
                        ForEach(Array(chartPoints.enumerated()), id: \.offset) { _, point in
                            LineMark(
                                x: .value("Day", point.date),
                                y: .value("mcg", point.value)
                            )
                            .foregroundStyle(biotinColor)
                            .interpolationMethod(.catmullRom)

                            AreaMark(
                                x: .value("Day", point.date),
                                y: .value("mcg", point.value)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [biotinColor.opacity(0.2), biotinColor.opacity(0)],
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
                    .chartYScale(domain: 0...(max(softGoal * 1.3, (chartPoints.map(\.value).max() ?? softGoal) * 1.2)))
                    .chartXAxis(.hidden)
                    .chartYAxis {
                        AxisMarks(position: .leading, values: [10, 20, 30]) { value in
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
                    .accessibilityLabel("Dietary biotin trend last seven days")
                }
            }
            .padding(16)
        }
        .accessibilityIdentifier(SurfaceID.dietaryBiotinCard)
    }


    private func formatMcg(_ v: Double) -> String {
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

enum DietaryBiotinBaseline {
    static func average(
        from history: [DailyHealthData],
        window: Int = 7,
        fallback: Double
    ) -> Double {
        let values = history
            .sorted { $0.date > $1.date }
            .prefix(window)
            .compactMap { $0.nutrition.biotinMcg }
            .filter { $0 >= 0 }
        guard !values.isEmpty else { return fallback }
        return values.reduce(0, +) / Double(values.count)
    }
}
