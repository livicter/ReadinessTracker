import SwiftUI
import Charts

/// Elevates `nutrition.vitaminEMg` (HK `dietaryVitaminE`) into Tonight | Baseline
/// on Today Body after Vitamin A. Net-new NutritionSummary + HK (#203).
/// Prefer dietaryVitaminE — clear leftover vitamin. Higher is better (soft 15 mg).
struct DietaryVitaminETonightBaselineCard: View {
    let vitaminEMg: Double?
    let history: [(date: Date, mg: Double)]
    let baselineMg: Double

    private let softGoal = 15.0
    private let buildingFloor = 10.0

    private var tonight: Double { max(0, vitaminEMg ?? 0) }

    private var base: Double {
        let b = baselineMg > 0 ? baselineMg : tonight
        return max(0, b)
    }

    private var delta: Double { tonight - base }

    private var status: (label: String, color: Color) {
        if vitaminEMg == nil { return ("No reading", RTColor.secondaryText) }
        // Higher vitamin E is generally favorable (soft ~15 mg goal).
        if tonight >= softGoal { return ("Met", RTColor.optimal) }
        if tonight >= buildingFloor { return ("Building", RTColor.good) }
        if tonight >= softGoal * 0.4 { return ("Low", RTColor.caution) }
        return ("Very low", RTColor.warning)
    }

    private var sparklineValues: [Double] {
        Array(history.sorted { $0.date < $1.date }.suffix(7).map(\.mg))
    }

    private var chartPoints: [(date: Date, value: Double)] {
        history.sorted { $0.date < $1.date }.map { (date: $0.date, value: $0.mg) }
    }

    private var deltaCaption: String {
        guard vitaminEMg != nil else { return "No vitamin E logged" }
        let sign = delta >= 0 ? "+" : ""
        return "\(sign)\(formatMg(abs(delta))) mg vs baseline"
    }

    private var limitCaption: String {
        "\(Int((min(1.2, tonight / softGoal) * 100).rounded()))% of \(Int(softGoal)) mg goal"
    }

    private let vitaminEColor = Color(hex: "AC8E68")

    var body: some View {
        Group {
            if vitaminEMg != nil {
                cardBody
            }
        }
    }

    private var cardBody: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Vitamin E")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(RTColor.primaryText)

                        Text("Intake · \(status.label)")
                            .font(.subheadline)
                            .foregroundStyle(status.color)
                    }

                    Spacer()

                    Text(formatMg(tonight))
                        .font(.title2.weight(.bold).monospacedDigit())
                        .foregroundStyle(status.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(status.color.opacity(0.12))
                        .clipShape(Capsule())
                        .accessibilityLabel("\(formatMg(tonight)) milligrams vitamin E, \(status.label)")
                }

                HStack(spacing: 12) {
                    dualColumn(
                        label: "Tonight",
                        valueText: formatMg(tonight),
                        unit: "mg",
                        color: status.color,
                        caption: limitCaption,
                        icon: "sun.max.fill"
                    )

                    Rectangle()
                        .fill(RTColor.divider)
                        .frame(width: 1)
                        .padding(.vertical, 4)

                    dualColumn(
                        label: "Baseline",
                        valueText: base > 0 ? formatMg(base) : "—",
                        unit: "mg",
                        color: RTColor.secondaryText,
                        caption: "7-day avg",
                        icon: "chart.line.uptrend.xyaxis"
                    )
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier(SurfaceID.dietaryVitaminEBaselineCallout)

                if sparklineValues.count >= 2 {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("7-Day Vitamin E")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(RTColor.secondaryText)
                            Spacer()
                            Text(deltaCaption)
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(delta >= 0 ? RTColor.optimal : RTColor.caution)
                                .monospacedDigit()
                        }
                        AnimatedSparkline(data: sparklineValues, color: vitaminEColor)
                            .frame(height: 28)
                            .accessibilityIdentifier(SurfaceID.dietaryVitaminESpark)
                    }
                }

                if chartPoints.count >= 3 {
                    Chart {
                        ForEach(Array(chartPoints.enumerated()), id: \.offset) { _, point in
                            LineMark(
                                x: .value("Day", point.date),
                                y: .value("mg", point.value)
                            )
                            .foregroundStyle(vitaminEColor)
                            .interpolationMethod(.catmullRom)

                            AreaMark(
                                x: .value("Day", point.date),
                                y: .value("mg", point.value)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [vitaminEColor.opacity(0.2), vitaminEColor.opacity(0)],
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
                        AxisMarks(position: .leading, values: [5, 10, 15]) { value in
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
                    .accessibilityLabel("Dietary vitamin E trend last seven days")
                }
            }
            .padding(16)
        }
        .accessibilityIdentifier(SurfaceID.dietaryVitaminECard)
    }


    private func formatMg(_ v: Double) -> String {
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

enum DietaryVitaminEBaseline {
    static func average(
        from history: [DailyHealthData],
        window: Int = 7,
        fallback: Double
    ) -> Double {
        let values = history
            .sorted { $0.date > $1.date }
            .prefix(window)
            .compactMap { $0.nutrition.vitaminEMg }
            .filter { $0 >= 0 }
        guard !values.isEmpty else { return fallback }
        return values.reduce(0, +) / Double(values.count)
    }
}
