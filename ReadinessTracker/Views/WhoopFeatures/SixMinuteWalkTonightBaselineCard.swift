import SwiftUI
import Charts

/// Elevates HealthKit `sixMinuteWalkTestDistance` (m) into Tonight | Baseline on
/// Today body after Stair Descent. Net-new DailyHealthData + HK (#151).
/// Prefer 6MWT — unused clinical mobility after stair pair; stronger readiness signal than swim/cadence.
struct SixMinuteWalkTonightBaselineCard: View {
    let meters: Double?
    let history: [(date: Date, meters: Double)]
    let baseline: Double

    private var tonight: Double? { meters.map { max(0, $0) } }

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
        // Typical adult 6MWT ~400–700 m (age/sex vary).
        if t >= 500 { return ("Strong", RTColor.optimal) }
        if t >= 400 { return ("Solid", RTColor.good) }
        if t >= 300 { return ("Fair", RTColor.caution) }
        return ("Low", RTColor.warning)
    }

    private var sparklineValues: [Double] {
        Array(history.sorted { $0.date < $1.date }.suffix(7).map(\.meters))
    }

    private var chartPoints: [(date: Date, value: Double)] {
        history.sorted { $0.date < $1.date }.map { (date: $0.date, value: $0.meters) }
    }

    private var deltaCaption: String {
        guard tonight != nil else { return "No six-minute walk logged" }
        let sign = delta >= 0 ? "+" : ""
        return String(format: "%@%.0f m vs baseline", sign, delta)
    }

    private let walkColor = Color(hex: "30B0C7")

    var body: some View {
        Group {
            if tonight != nil || !history.isEmpty {
                cardBody
                    .accessibilityIdentifier(SurfaceID.sixMinuteWalkCard)
            }
        }
    }

    private var cardBody: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Six-Minute Walk")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(RTColor.primaryText)

                        Text("6MWT · \(status.label)")
                            .font(.subheadline)
                            .foregroundStyle(status.color)
                    }

                    Spacer()

                    Text(tonight.map { String(format: "%.0f", $0) } ?? "—")
                        .font(.title2.weight(.bold).monospacedDigit())
                        .foregroundStyle(status.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(status.color.opacity(0.12))
                        .clipShape(Capsule())
                        .accessibilityLabel(
                            tonight.map { "Stair ascent \(String(format: "%.0f", $0)) meters per second, \(status.label)" }
                                ?? "No six-minute walk"
                        )
                }

                HStack(spacing: 12) {
                    dualColumn(
                        label: "Tonight",
                        valueText: tonight.map { String(format: "%.0f", $0) } ?? "—",
                        unit: "m",
                        color: status.color,
                        caption: "Walk distance",
                        icon: "figure.walk"
                    )

                    Rectangle()
                        .fill(RTColor.divider)
                        .frame(width: 1)
                        .padding(.vertical, 4)

                    dualColumn(
                        label: "Baseline",
                        valueText: base > 0 ? String(format: "%.0f", base) : "—",
                        unit: "m",
                        color: RTColor.secondaryText,
                        caption: "7-day avg",
                        icon: "chart.line.uptrend.xyaxis"
                    )
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier(SurfaceID.sixMinuteWalkBaselineCallout)

                if sparklineValues.count >= 2 {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("7-Day Six-Minute Walk")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(RTColor.secondaryText)
                            Spacer()
                            Text(deltaCaption)
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(delta >= 0 ? RTColor.optimal : RTColor.caution)
                                .monospacedDigit()
                        }
                        AnimatedSparkline(data: sparklineValues, color: walkColor)
                            .frame(height: 28)
                            .accessibilityIdentifier(SurfaceID.sixMinuteWalkSpark)
                    }
                }

                if chartPoints.count >= 3 {
                    Chart {
                        ForEach(Array(chartPoints.enumerated()), id: \.offset) { _, point in
                            LineMark(
                                x: .value("Day", point.date),
                                y: .value("m", point.value)
                            )
                            .foregroundStyle(walkColor)
                            .interpolationMethod(.catmullRom)

                            AreaMark(
                                x: .value("Day", point.date),
                                y: .value("m", point.value)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [walkColor.opacity(0.22), walkColor.opacity(0)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .interpolationMethod(.catmullRom)
                        }

                        RuleMark(y: .value("Solid", 400))
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
                                    Text(String(format: "%.0f", v))
                                        .font(.caption2)
                                        .foregroundStyle(RTColor.secondaryText)
                                }
                            }
                        }
                    }
                    .frame(height: 88)
                    .accessibilityLabel("Stair ascent trend last seven days")
                }
            }
            .padding(16)
        }
        .accessibilityIdentifier(SurfaceID.sixMinuteWalkCard)
    }

    private var yDomain: ClosedRange<Double> {
        let vals = chartPoints.map(\.value) + [base, tonight ?? base, 0.35].filter { $0 > 0 }
        let lo = max(200, (vals.min() ?? 350) - 30)
        let hi = max(lo + 80, (vals.max() ?? 550) + 30)
        return lo...hi
    }

    private var yMarks: [Double] {
        let mid = (yDomain.lowerBound + yDomain.upperBound) / 2
        return [
            (yDomain.lowerBound * 100).rounded() / 100,
            (mid * 100).rounded() / 100,
            (yDomain.upperBound * 100).rounded() / 100
        ]
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

enum SixMinuteWalkBaseline {
    static func average(
        from history: [DailyHealthData],
        window: Int = 7,
        fallback: Double
    ) -> Double {
        let values = history
            .sorted { $0.date > $1.date }
            .prefix(window)
            .compactMap(\.sixMinuteWalkDistanceMeters)
            .filter { $0 > 0 }
        guard !values.isEmpty else { return fallback }
        return values.reduce(0, +) / Double(values.count)
    }
}
