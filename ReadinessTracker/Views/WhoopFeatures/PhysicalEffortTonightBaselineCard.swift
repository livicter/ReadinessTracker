import SwiftUI
import Charts

/// Elevates HealthKit `physicalEffortKcalPerHrKg` (meters) into Tonight | Baseline on
/// Today body after Cycling FTP. Net-new DailyHealthData + HK (#158).
/// Prefer physical effort over stroke count / underwater / cadence — clearest unused activity volume.
struct PhysicalEffortTonightBaselineCard: View {
    let effort: Double?
    let history: [(date: Date, effort: Double)]
    let baseline: Double

    private var tonight: Double? { effort.map { max(0, $0) } }

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
        // Physical effort intensity (kcal/hr·kg).
        if t >= 5.0 { return ("High", RTColor.optimal) }
        if t >= 3.0 { return ("Solid", RTColor.good) }
        if t >= 1.5 { return ("Easy", RTColor.caution) }
        return ("Low", RTColor.warning)
    }

    private var sparklineValues: [Double] {
        Array(history.sorted { $0.date < $1.date }.suffix(7).map(\.effort))
    }

    private var chartPoints: [(date: Date, value: Double)] {
        history.sorted { $0.date < $1.date }.map { (date: $0.date, value: $0.effort) }
    }

    private var deltaCaption: String {
        guard tonight != nil else { return "No physical effort logged" }
        let sign = delta >= 0 ? "+" : ""
        return String(format: "%@%.0f vs baseline", sign, delta)
    }

    private let effortColor = Color(hex: "FF375F")

    var body: some View {
        Group {
            if tonight != nil || !history.isEmpty {
                cardBody
                    .accessibilityIdentifier(SurfaceID.physicalEffortCard)
            }
        }
    }

    private var cardBody: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Physical Effort")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(RTColor.primaryText)

                        Text("Effort · \(status.label)")
                            .font(.subheadline)
                            .foregroundStyle(status.color)
                    }

                    Spacer()

                    Text(tonight.map { String(format: "%.1f", $0) } ?? "—")
                        .font(.title2.weight(.bold).monospacedDigit())
                        .foregroundStyle(status.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(status.color.opacity(0.12))
                        .clipShape(Capsule())
                        .accessibilityLabel(
                            tonight.map { "Physical Effort \(String(format: "%.1f", $0)) watts, \(status.label)" }
                                ?? "No physical effort"
                        )
                }

                HStack(spacing: 12) {
                    dualColumn(
                        label: "Tonight",
                        valueText: tonight.map { String(format: "%.1f", $0) } ?? "—",
                        unit: "kcal",
                        color: status.color,
                        caption: "Stroke count",
                        icon: "gauge.with.needle"
                    )

                    Rectangle()
                        .fill(RTColor.divider)
                        .frame(width: 1)
                        .padding(.vertical, 4)

                    dualColumn(
                        label: "Baseline",
                        valueText: base > 0 ? String(format: "%.1f", base) : "—",
                        unit: "kcal",
                        color: RTColor.secondaryText,
                        caption: "7-day avg",
                        icon: "chart.line.uptrend.xyaxis"
                    )
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier(SurfaceID.physicalEffortBaselineCallout)

                if sparklineValues.count >= 2 {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("7-Day Physical Effort")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(RTColor.secondaryText)
                            Spacer()
                            Text(deltaCaption)
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(delta >= 0 ? RTColor.optimal : RTColor.caution)
                                .monospacedDigit()
                        }
                        AnimatedSparkline(data: sparklineValues, color: effortColor)
                            .frame(height: 28)
                            .accessibilityIdentifier(SurfaceID.physicalEffortSpark)
                    }
                }

                if chartPoints.count >= 3 {
                    Chart {
                        ForEach(Array(chartPoints.enumerated()), id: \.offset) { _, point in
                            LineMark(
                                x: .value("Day", point.date),
                                y: .value("E", point.value)
                            )
                            .foregroundStyle(effortColor)
                            .interpolationMethod(.catmullRom)

                            AreaMark(
                                x: .value("Day", point.date),
                                y: .value("E", point.value)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [effortColor.opacity(0.22), effortColor.opacity(0)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .interpolationMethod(.catmullRom)
                        }

                        RuleMark(y: .value("Solid", 3.0))
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
                                    Text("\(Int(v))")
                                        .font(.caption2)
                                        .foregroundStyle(RTColor.secondaryText)
                                }
                            }
                        }
                    }
                    .frame(height: 88)
                    .accessibilityLabel("Physical Effort trend last seven days")
                }
            }
            .padding(16)
        }
        .accessibilityIdentifier(SurfaceID.physicalEffortCard)
    }

    private var yDomain: ClosedRange<Double> {
        let vals = chartPoints.map(\.value) + [base, tonight ?? base, 3.0].filter { $0 > 0 }
        let lo = max(0.5, (vals.min() ?? 1.5) - 0.4)
        let hi = max(lo + 2.0, (vals.max() ?? 5.0) + 0.5)
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

enum PhysicalEffortBaseline {
    static func average(
        from history: [DailyHealthData],
        window: Int = 7,
        fallback: Double
    ) -> Double {
        let values = history
            .sorted { $0.date > $1.date }
            .prefix(window)
            .compactMap(\.physicalEffortKcalPerHrKg)
            .filter { $0 > 0 }
        guard !values.isEmpty else { return fallback }
        return values.reduce(0, +) / Double(values.count)
    }
}
