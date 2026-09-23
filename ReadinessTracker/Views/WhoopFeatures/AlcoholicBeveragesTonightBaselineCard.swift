import SwiftUI
import Charts

/// Elevates `nutrition.alcoholicBeverages` (HK `numberOfAlcoholicBeverages`) into
/// Tonight | Baseline on Today Body after Dietary Sugar. Net-new NutritionSummary + HK (#177).
/// Prefer last dietary leftover — distinct from journal alcoholDrinks check-in.
struct AlcoholicBeveragesTonightBaselineCard: View {
    let count: Double?
    let history: [(date: Date, count: Double)]
    let baseline: Double

    private var tonight: Double { max(0, count ?? 0) }

    private var base: Double {
        let b = baseline > 0 ? baseline : tonight
        return max(0, b)
    }

    private var delta: Double { tonight - base }

    private var status: (label: String, color: Color) {
        if count == nil { return ("No reading", RTColor.secondaryText) }
        // Lower is better for recovery.
        if tonight <= 0 { return ("None", RTColor.optimal) }
        if tonight <= 1 { return ("One", RTColor.good) }
        if tonight <= 2 { return ("Few", RTColor.caution) }
        return ("Many", RTColor.warning)
    }

    private var sparklineValues: [Double] {
        Array(history.sorted { $0.date < $1.date }.suffix(7).map(\.count))
    }

    private var chartPoints: [(date: Date, value: Double)] {
        history.sorted { $0.date < $1.date }.map { (date: $0.date, value: $0.count) }
    }

    private var deltaCaption: String {
        guard count != nil else { return "No drinks logged" }
        let sign = delta >= 0 ? "+" : ""
        return "\(sign)\(Int(delta.rounded())) vs baseline"
    }

    private let alcoholColor = Color(hex: "BF5AF2")

    var body: some View {
        Group {
            if count != nil {
                cardBody
            }
        }
    }

    private var cardBody: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Alcoholic Beverages")
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
                        .accessibilityLabel("\(Int(tonight.rounded())) alcoholic beverages, \(status.label)")
                }

                HStack(spacing: 12) {
                    dualColumn(
                        label: "Tonight",
                        valueText: "\(Int(tonight.rounded()))",
                        unit: "drinks",
                        color: status.color,
                        caption: "Today count",
                        icon: "wineglass.fill"
                    )

                    Rectangle()
                        .fill(RTColor.divider)
                        .frame(width: 1)
                        .padding(.vertical, 4)

                    dualColumn(
                        label: "Baseline",
                        valueText: base > 0 ? String(format: "%.1f", base) : "—",
                        unit: "drinks",
                        color: RTColor.secondaryText,
                        caption: "7-day avg",
                        icon: "chart.line.uptrend.xyaxis"
                    )
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier(SurfaceID.alcoholicBeveragesBaselineCallout)

                if sparklineValues.count >= 2 {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("7-Day Drinks")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(RTColor.secondaryText)
                            Spacer()
                            Text(deltaCaption)
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(delta <= 0 ? RTColor.optimal : RTColor.caution)
                                .monospacedDigit()
                        }
                        AnimatedSparkline(data: sparklineValues, color: alcoholColor)
                            .frame(height: 28)
                            .accessibilityIdentifier(SurfaceID.alcoholicBeveragesSpark)
                    }
                }

                if chartPoints.count >= 3 {
                    Chart {
                        ForEach(Array(chartPoints.enumerated()), id: \.offset) { _, point in
                            LineMark(
                                x: .value("Day", point.date),
                                y: .value("drinks", point.value)
                            )
                            .foregroundStyle(alcoholColor)
                            .interpolationMethod(.catmullRom)

                            AreaMark(
                                x: .value("Day", point.date),
                                y: .value("drinks", point.value)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [alcoholColor.opacity(0.2), alcoholColor.opacity(0)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .interpolationMethod(.catmullRom)
                        }

                        RuleMark(y: .value("One", 1))
                            .foregroundStyle(RTColor.secondaryText.opacity(0.35))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    }
                    .chartYScale(domain: 0...(max(3.0, (chartPoints.map(\.value).max() ?? 3) + 1)))
                    .chartXAxis(.hidden)
                    .chartYAxis {
                        AxisMarks(position: .leading, values: [0, 1, 2]) { value in
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
                    .accessibilityLabel("Alcoholic beverages trend last seven days")
                }
            }
            .padding(16)
        }
        .accessibilityIdentifier(SurfaceID.alcoholicBeveragesCard)
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

enum AlcoholicBeveragesBaseline {
    static func average(
        from history: [DailyHealthData],
        window: Int = 7,
        fallback: Double
    ) -> Double {
        let values = history
            .sorted { $0.date > $1.date }
            .prefix(window)
            .compactMap { $0.nutrition.alcoholicBeverages }
            .filter { $0 >= 0 }
        guard !values.isEmpty else { return fallback }
        return values.reduce(0, +) / Double(values.count)
    }
}
