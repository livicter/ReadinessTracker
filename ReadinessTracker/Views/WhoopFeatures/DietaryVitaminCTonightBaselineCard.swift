import SwiftUI
import Charts

/// Elevates `nutrition.vitaminCMg` (HK `dietaryVitaminC`) into Tonight | Baseline
/// on Today Body after Saturated Fat. Net-new NutritionSummary + HK (#194).
/// Prefer dietaryVitaminC — unused vitamin leftover after sat fat. Higher is better (soft 90 mg).
struct DietaryVitaminCTonightBaselineCard: View {
    let vitaminCMg: Double?
    let history: [(date: Date, mg: Double)]
    let baselineMg: Double

    private let softGoal = 90.0
    private let buildingFloor = 60.0

    private var tonight: Double { max(0, vitaminCMg ?? 0) }

    private var base: Double {
        let b = baselineMg > 0 ? baselineMg : tonight
        return max(0, b)
    }

    private var delta: Double { tonight - base }

    private var status: (label: String, color: Color) {
        if vitaminCMg == nil { return ("No reading", RTColor.secondaryText) }
        // Higher vitaminC is generally favorable (soft ~90 mg goal).
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
        guard vitaminCMg != nil else { return "No vitaminC logged" }
        let sign = delta >= 0 ? "+" : ""
        return "\(sign)\(Int(delta.rounded())) mg vs baseline"
    }

    private var limitCaption: String {
        "\(Int((min(1.2, tonight / softGoal) * 100).rounded()))% of \(Int(softGoal)) mg goal"
    }

    private let vitaminCColor = Color(hex: "FFD60A")

    var body: some View {
        Group {
            if vitaminCMg != nil {
                cardBody
            }
        }
    }

    private var cardBody: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Vitamin C")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(RTColor.primaryText)

                        Text("Intake · \(status.label)")
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
                        .accessibilityLabel("\(Int(tonight.rounded())) milligrams vitaminC, \(status.label)")
                }

                HStack(spacing: 12) {
                    dualColumn(
                        label: "Tonight",
                        valueText: "\(Int(tonight.rounded()))",
                        unit: "mg",
                        color: status.color,
                        caption: limitCaption,
                        icon: "carrot.fill"
                    )

                    Rectangle()
                        .fill(RTColor.divider)
                        .frame(width: 1)
                        .padding(.vertical, 4)

                    dualColumn(
                        label: "Baseline",
                        valueText: base > 0 ? "\(Int(base.rounded()))" : "—",
                        unit: "mg",
                        color: RTColor.secondaryText,
                        caption: "7-day avg",
                        icon: "chart.line.uptrend.xyaxis"
                    )
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier(SurfaceID.dietaryVitaminCBaselineCallout)

                if sparklineValues.count >= 2 {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("7-Day Vitamin C")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(RTColor.secondaryText)
                            Spacer()
                            Text(deltaCaption)
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(delta >= 0 ? RTColor.optimal : RTColor.caution)
                                .monospacedDigit()
                        }
                        AnimatedSparkline(data: sparklineValues, color: vitaminCColor)
                            .frame(height: 28)
                            .accessibilityIdentifier(SurfaceID.dietaryVitaminCSpark)
                    }
                }

                if chartPoints.count >= 3 {
                    Chart {
                        ForEach(Array(chartPoints.enumerated()), id: \.offset) { _, point in
                            LineMark(
                                x: .value("Day", point.date),
                                y: .value("g", point.value)
                            )
                            .foregroundStyle(vitaminCColor)
                            .interpolationMethod(.catmullRom)

                            AreaMark(
                                x: .value("Day", point.date),
                                y: .value("g", point.value)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [vitaminCColor.opacity(0.2), vitaminCColor.opacity(0)],
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
                        AxisMarks(position: .leading, values: [25, 50]) { value in
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
                    .accessibilityLabel("Dietary vitaminC trend last seven days")
                }
            }
            .padding(16)
        }
        .accessibilityIdentifier(SurfaceID.dietaryVitaminCCard)
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

enum DietaryVitaminCBaseline {
    static func average(
        from history: [DailyHealthData],
        window: Int = 7,
        fallback: Double
    ) -> Double {
        let values = history
            .sorted { $0.date > $1.date }
            .prefix(window)
            .compactMap { $0.nutrition.vitaminCMg }
            .filter { $0 >= 0 }
        guard !values.isEmpty else { return fallback }
        return values.reduce(0, +) / Double(values.count)
    }
}
