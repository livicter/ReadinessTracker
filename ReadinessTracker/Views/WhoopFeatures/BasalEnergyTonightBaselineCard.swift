import SwiftUI
import Charts

/// Elevates HealthKit `basalEnergyBurned` (kcal) into Tonight | Baseline on
/// Today body after Active Calories. Net-new DailyHealthData + HK (#184).
/// Prefer basalEnergyBurned — resting burn distinct from active energy dual.
struct BasalEnergyTonightBaselineCard: View {
    let kcal: Double?
    let history: [(date: Date, kcal: Double)]
    let baseline: Double

    private let softGoal = 1600.0

    private var tonight: Double? { kcal.map { max(0, $0) } }

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
        // Resting burn glance vs soft typical band + baseline.
        if abs(delta) < 40 { return ("Steady", RTColor.optimal) }
        if t >= softGoal { return ("Solid", RTColor.good) }
        if t >= softGoal * 0.85 { return ("Building", RTColor.caution) }
        return ("Low", RTColor.warning)
    }

    private var sparklineValues: [Double] {
        Array(history.sorted { $0.date < $1.date }.suffix(7).map(\.kcal))
    }

    private var chartPoints: [(date: Date, value: Double)] {
        history.sorted { $0.date < $1.date }.map { (date: $0.date, value: $0.kcal) }
    }

    private var deltaCaption: String {
        guard tonight != nil else { return "No basal logged" }
        let sign = delta >= 0 ? "+" : ""
        return "\(sign)\(Int(delta.rounded())) kcal vs baseline"
    }

    private let basalColor = Color(hex: "FF9500")

    var body: some View {
        Group {
            if tonight != nil || !history.isEmpty {
                cardBody
                    .accessibilityIdentifier(SurfaceID.basalEnergyCard)
            }
        }
    }

    private var cardBody: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Basal Energy")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(RTColor.primaryText)

                        Text("Resting · \(status.label)")
                            .font(.subheadline)
                            .foregroundStyle(status.color)
                    }

                    Spacer()

                    Text(tonight.map { "\(Int($0.rounded()))" } ?? "—")
                        .font(.title2.weight(.bold).monospacedDigit())
                        .foregroundStyle(status.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(status.color.opacity(0.12))
                        .clipShape(Capsule())
                        .accessibilityLabel(
                            tonight.map { "Basal energy \(Int($0.rounded())) kilocalories, \(status.label)" }
                                ?? "No basal logged"
                        )
                }

                HStack(spacing: 12) {
                    dualColumn(
                        label: "Tonight",
                        valueText: tonight.map { "\(Int($0.rounded()))" } ?? "—",
                        unit: "kcal",
                        color: status.color,
                        caption: "Resting burn",
                        icon: "flame.fill"
                    )

                    Rectangle()
                        .fill(RTColor.divider)
                        .frame(width: 1)
                        .padding(.vertical, 4)

                    dualColumn(
                        label: "Baseline",
                        valueText: base > 0 ? "\(Int(base.rounded()))" : "—",
                        unit: "kcal",
                        color: RTColor.secondaryText,
                        caption: "7-day avg",
                        icon: "chart.line.uptrend.xyaxis"
                    )
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier(SurfaceID.basalEnergyBaselineCallout)

                if sparklineValues.count >= 2 {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("7-Day Basal")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(RTColor.secondaryText)
                            Spacer()
                            Text(deltaCaption)
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(abs(delta) < 40 ? RTColor.optimal : RTColor.caution)
                                .monospacedDigit()
                        }
                        AnimatedSparkline(data: sparklineValues, color: basalColor)
                            .frame(height: 28)
                            .accessibilityIdentifier(SurfaceID.basalEnergySpark)
                    }
                }

                if chartPoints.count >= 3 {
                    Chart {
                        ForEach(Array(chartPoints.enumerated()), id: \.offset) { _, point in
                            LineMark(
                                x: .value("Day", point.date),
                                y: .value("kcal", point.value)
                            )
                            .foregroundStyle(basalColor)
                            .interpolationMethod(.catmullRom)

                            AreaMark(
                                x: .value("Day", point.date),
                                y: .value("kcal", point.value)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [basalColor.opacity(0.2), basalColor.opacity(0)],
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
                                    Text("\(Int(v.rounded()))")
                                        .font(.caption2)
                                        .foregroundStyle(RTColor.secondaryText)
                                }
                            }
                        }
                    }
                    .frame(height: 88)
                    .accessibilityLabel("Basal energy trend last seven days")
                }
            }
            .padding(16)
        }
        .accessibilityIdentifier(SurfaceID.basalEnergyCard)
    }

    private var yDomain: ClosedRange<Double> {
        let vals = chartPoints.map(\.value) + [base, tonight ?? base, softGoal].filter { $0 >= 0 }
        let lo = max(0.0, (vals.min() ?? 1200) - 100)
        let hi = max(softGoal * 1.15, (vals.max() ?? softGoal) + 100)
        return lo...hi
    }

    private var yMarks: [Double] {
        let mid = ((yDomain.lowerBound + yDomain.upperBound) / 2).rounded()
        return [yDomain.lowerBound.rounded(), mid, yDomain.upperBound.rounded()]
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

enum BasalEnergyBaseline {
    static func average(
        from history: [DailyHealthData],
        window: Int = 7,
        fallback: Double
    ) -> Double {
        let values = history
            .sorted { $0.date > $1.date }
            .prefix(window)
            .compactMap(\.basalEnergyKcal)
            .filter { $0 > 0 }
        guard !values.isEmpty else { return fallback }
        return values.reduce(0, +) / Double(values.count)
    }
}
