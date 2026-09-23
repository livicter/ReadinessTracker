import SwiftUI
import Charts

/// Elevates `nutrition.saturatedFatGrams` (HK `dietaryFatSaturated`) into Tonight | Baseline
/// on Today Body after Dietary Cholesterol. Net-new NutritionSummary + HK (#193).
/// Prefer dietaryFatSaturated — clear intake leftover after cholesterol. Lower is better (soft 20 g).
struct DietarySatFatTonightBaselineCard: View {
    let saturatedFatGrams: Double?
    let history: [(date: Date, grams: Double)]
    let baselineGrams: Double

    private let softLimit = 20.0
    private let cautionLimit = 30.0

    private var tonight: Double { max(0, saturatedFatGrams ?? 0) }

    private var base: Double {
        let b = baselineGrams > 0 ? baselineGrams : tonight
        return max(0, b)
    }

    private var delta: Double { tonight - base }

    private var status: (label: String, color: Color) {
        if saturatedFatGrams == nil { return ("No reading", RTColor.secondaryText) }
        if tonight >= cautionLimit { return ("High", RTColor.warning) }
        if tonight >= softLimit { return ("Elevated", RTColor.caution) }
        if tonight >= softLimit * 0.5 { return ("Moderate", RTColor.good) }
        return ("Clear", RTColor.optimal)
    }

    private var sparklineValues: [Double] {
        Array(history.sorted { $0.date < $1.date }.suffix(7).map(\.grams))
    }

    private var chartPoints: [(date: Date, value: Double)] {
        history.sorted { $0.date < $1.date }.map { (date: $0.date, value: $0.grams) }
    }

    private var deltaCaption: String {
        guard saturatedFatGrams != nil else { return "No satFat logged" }
        let sign = delta >= 0 ? "+" : ""
        return "\(sign)\(Int(delta.rounded())) g vs baseline"
    }

    private var limitCaption: String {
        "\(Int((min(1.2, tonight / softLimit) * 100).rounded()))% of \(Int(softLimit)) g limit"
    }

    private let satFatColor = Color(hex: "FF9F0A")

    var body: some View {
        Group {
            if saturatedFatGrams != nil {
                cardBody
            }
        }
    }

    private var cardBody: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Saturated Fat")
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
                        .accessibilityLabel("\(Int(tonight.rounded())) grams saturated fat, \(status.label)")
                }

                HStack(spacing: 12) {
                    dualColumn(
                        label: "Tonight",
                        valueText: "\(Int(tonight.rounded()))",
                        unit: "g",
                        color: status.color,
                        caption: limitCaption,
                        icon: "circle.lefthalf.filled"
                    )

                    Rectangle()
                        .fill(RTColor.divider)
                        .frame(width: 1)
                        .padding(.vertical, 4)

                    dualColumn(
                        label: "Baseline",
                        valueText: base > 0 ? "\(Int(base.rounded()))" : "—",
                        unit: "g",
                        color: RTColor.secondaryText,
                        caption: "7-day avg",
                        icon: "chart.line.uptrend.xyaxis"
                    )
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier(SurfaceID.dietarySatFatBaselineCallout)

                if sparklineValues.count >= 2 {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("7-Day Sat Fat")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(RTColor.secondaryText)
                            Spacer()
                            Text(deltaCaption)
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(delta <= 0 ? RTColor.optimal : RTColor.caution)
                                .monospacedDigit()
                        }
                        AnimatedSparkline(data: sparklineValues, color: satFatColor)
                            .frame(height: 28)
                            .accessibilityIdentifier(SurfaceID.dietarySatFatSpark)
                    }
                }

                if chartPoints.count >= 3 {
                    Chart {
                        ForEach(Array(chartPoints.enumerated()), id: \.offset) { _, point in
                            LineMark(
                                x: .value("Day", point.date),
                                y: .value("g", point.value)
                            )
                            .foregroundStyle(satFatColor)
                            .interpolationMethod(.catmullRom)

                            AreaMark(
                                x: .value("Day", point.date),
                                y: .value("g", point.value)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [satFatColor.opacity(0.2), satFatColor.opacity(0)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .interpolationMethod(.catmullRom)
                        }

                        RuleMark(y: .value("Limit", softLimit))
                            .foregroundStyle(RTColor.secondaryText.opacity(0.35))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    }
                    .chartYScale(domain: 0...(max(softLimit * 1.3, (chartPoints.map(\.value).max() ?? softLimit) * 1.2)))
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
                    .accessibilityLabel("Dietary satFat trend last seven days")
                }
            }
            .padding(16)
        }
        .accessibilityIdentifier(SurfaceID.dietarySatFatCard)
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

enum DietarySatFatBaseline {
    static func average(
        from history: [DailyHealthData],
        window: Int = 7,
        fallback: Double
    ) -> Double {
        let values = history
            .sorted { $0.date > $1.date }
            .prefix(window)
            .compactMap { $0.nutrition.saturatedFatGrams }
            .filter { $0 >= 0 }
        guard !values.isEmpty else { return fallback }
        return values.reduce(0, +) / Double(values.count)
    }
}
