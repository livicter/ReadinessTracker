import SwiftUI
import Charts

/// Elevates `nutrition.waterLiters` into a Tonight | Baseline dual on Today Body.
/// NutritionSummaryCard (#106) remains the strain-detail glance with circular wells —
/// not re-chromed. Soft 2.5 L target matches coaching / NutritionSummary.
struct HydrationTonightBaselineCard: View {
    let waterLiters: Double?
    let caffeineMg: Double?
    let proteinGrams: Double?
    let history: [(date: Date, water: Double)]
    let baselineLiters: Double

    private let waterTarget = 2.5
    private let caffeineLimit = 200.0
    private let proteinTarget = 100.0

    private var tonight: Double { max(0, waterLiters ?? 0) }

    private var base: Double {
        let b = baselineLiters > 0 ? baselineLiters : tonight
        return max(0, b)
    }

    private var delta: Double { tonight - base }

    private var status: (label: String, color: Color) {
        var issues: [String] = []
        if tonight < 1.5 { issues.append("Low water") }
        if let c = caffeineMg, c >= 250 { issues.append("High caffeine") }
        if let p = proteinGrams, p < 100 { issues.append("Low protein") }
        if issues.isEmpty {
            if tonight >= waterTarget { return ("Hydrated", RTColor.optimal) }
            return ("On track", RTColor.good)
        }
        if issues.count == 1 { return (issues[0], RTColor.caution) }
        return ("Needs attention", RTColor.warning)
    }

    private var sparklineValues: [Double] {
        Array(history.sorted { $0.date < $1.date }.suffix(7).map(\.water))
    }

    private var chartPoints: [(date: Date, value: Double)] {
        history.sorted { $0.date < $1.date }.map { (date: $0.date, value: $0.water) }
    }

    private var deltaCaption: String {
        let sign = delta >= 0 ? "+" : ""
        return String(format: "%@%.1f L vs baseline", sign, delta)
    }

    private var goalCaption: String {
        String(format: "%.0f%% of %.1f L goal", min(120, (tonight / waterTarget) * 100), waterTarget)
    }

    private var companionCaption: String {
        var parts: [String] = []
        if let c = caffeineMg {
            parts.append("\(Int(c)) mg caffeine")
        }
        if let p = proteinGrams {
            parts.append("\(Int(p)) g protein")
        }
        return parts.isEmpty ? "Water focus" : parts.joined(separator: " · ")
    }

    private let waterColor = Color(hex: "5AC8FA")

    var body: some View {
        Group {
            if waterLiters != nil {
                cardBody
            }
        }
    }

    private var cardBody: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Hydration")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(RTColor.primaryText)

                        Text("Water · \(status.label)")
                            .font(.subheadline)
                            .foregroundStyle(status.color)
                    }

                    Spacer()

                    Text(String(format: "%.1f L", tonight))
                        .font(.title2.weight(.bold).monospacedDigit())
                        .foregroundStyle(status.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(status.color.opacity(0.12))
                        .clipShape(Capsule())
                        .accessibilityLabel(String(format: "%.1f liters water, %@", tonight, status.label))
                }

                HStack(spacing: 12) {
                    dualColumn(
                        label: "Tonight",
                        valueText: String(format: "%.1f", tonight),
                        unit: "L",
                        color: status.color,
                        caption: goalCaption,
                        icon: "drop.fill"
                    )

                    Rectangle()
                        .fill(RTColor.divider)
                        .frame(width: 1)
                        .padding(.vertical, 4)

                    dualColumn(
                        label: "Baseline",
                        valueText: String(format: "%.1f", base),
                        unit: "L",
                        color: RTColor.secondaryText,
                        caption: "7-day average",
                        icon: "chart.line.flattrend.xyaxis"
                    )
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier(SurfaceID.hydrationBaselineCallout)

                Text(companionCaption)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(RTColor.secondaryText)
                    .accessibilityLabel(companionCaption)

                if sparklineValues.count >= 2 {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("7-Day Water")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(RTColor.secondaryText)
                            Spacer()
                            Text(deltaCaption)
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(delta < -0.3 ? RTColor.caution : RTColor.optimal)
                                .monospacedDigit()
                        }
                        AnimatedSparkline(data: sparklineValues, color: waterColor)
                            .frame(height: 28)
                            .accessibilityIdentifier(SurfaceID.hydrationSpark)
                    }
                }

                if chartPoints.count >= 3 {
                    Chart {
                        ForEach(Array(chartPoints.enumerated()), id: \.offset) { _, point in
                            LineMark(
                                x: .value("Day", point.date),
                                y: .value("Liters", point.value)
                            )
                            .foregroundStyle(waterColor)
                            .interpolationMethod(.catmullRom)

                            AreaMark(
                                x: .value("Day", point.date),
                                y: .value("Liters", point.value)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [waterColor.opacity(0.2), waterColor.opacity(0)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .interpolationMethod(.catmullRom)
                        }

                        RuleMark(y: .value("Goal", waterTarget))
                            .foregroundStyle(RTColor.secondaryText.opacity(0.35))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    }
                    .chartYScale(domain: 0...(max(3.2, (chartPoints.map(\.value).max() ?? 2.5) * 1.2)))
                    .chartXAxis(.hidden)
                    .chartYAxis {
                        AxisMarks(position: .leading, values: [1.5, 2.5]) { value in
                            AxisGridLine()
                            AxisValueLabel {
                                if let v = value.as(Double.self) {
                                    Text(String(format: "%.1f", v))
                                        .font(.caption2)
                                        .foregroundStyle(RTColor.secondaryText)
                                }
                            }
                        }
                    }
                    .frame(height: 88)
                    .accessibilityLabel("Water intake trend last seven days")
                }
            }
            .padding(16)
        }
        .accessibilityIdentifier(SurfaceID.hydrationCard)
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

enum HydrationBaseline {
    static func averageWater(
        from history: [DailyHealthData],
        window: Int = 7,
        fallback: Double
    ) -> Double {
        let values = history
            .sorted { $0.date > $1.date }
            .prefix(window)
            .compactMap { $0.nutrition.waterLiters }
            .filter { $0 > 0 }
        guard !values.isEmpty else { return fallback }
        return values.reduce(0, +) / Double(values.count)
    }
}
