import SwiftUI
import Charts

/// Elevates HealthKit `environmentalSoundReduction` (dB A-weighted ANC delta) into a
/// Tonight | Baseline dual on Today vitals after Sound Reduction.
/// Net-new DailyHealthData + HK wire (#138). Skin temp already dualled;
/// Watch sleepScore already on complications — sound reduction was strongest unused.
struct EnvSoundReductionTonightBaselineCard: View {
    let exposureDBA: Double?
    let history: [(date: Date, dba: Double)]
    let baseline: Double

    private var tonight: Double? { exposureDBA.map { max(0, $0) } }

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
        // Higher dB = more ambient attenuation (AirPods Pro ANC).
        if t >= 20 { return ("Strong", RTColor.optimal) }
        if t >= 12 { return ("Good", RTColor.good) }
        if t >= 6 { return ("Light", RTColor.caution) }
        return ("Minimal", RTColor.warning)
    }

    private var sparklineValues: [Double] {
        Array(history.sorted { $0.date < $1.date }.suffix(7).map(\.dba))
    }

    private var chartPoints: [(date: Date, value: Double)] {
        history.sorted { $0.date < $1.date }.map { (date: $0.date, value: $0.dba) }
    }

    private var deltaCaption: String {
        guard tonight != nil else { return "No sound reduction" }
        let sign = delta >= 0 ? "+" : ""
        return String(format: "%@%.0f dB vs baseline", sign, delta)
    }

    private let reductionColor = Color(hex: "30D158")

    var body: some View {
        Group {
            if tonight != nil || !history.isEmpty {
                cardBody
                    .accessibilityIdentifier(SurfaceID.envSoundReductionCard)
            }
        }
    }

    private var cardBody: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sound Reduction")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(RTColor.primaryText)

                        Text("Exposure · \(status.label)")
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
                            tonight.map { "Sound reduction \($0.rounded()) decibels, \(status.label)" }
                                ?? "No sound reduction"
                        )
                }

                HStack(spacing: 12) {
                    dualColumn(
                        label: "Tonight",
                        valueText: tonight.map { String(format: "%.0f", $0) } ?? "—",
                        unit: "dBA",
                        color: status.color,
                        caption: "ANC delta",
                        icon: "ear.and.waveform"
                    )

                    Rectangle()
                        .fill(RTColor.divider)
                        .frame(width: 1)
                        .padding(.vertical, 4)

                    dualColumn(
                        label: "Baseline",
                        valueText: base > 0 ? String(format: "%.0f", base) : "—",
                        unit: "dBA",
                        color: RTColor.secondaryText,
                        caption: "7-day avg",
                        icon: "chart.line.uptrend.xyaxis"
                    )
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier(SurfaceID.envSoundReductionBaselineCallout)

                if sparklineValues.count >= 2 {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("7-Day Sound Reduction")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(RTColor.secondaryText)
                            Spacer()
                            Text(deltaCaption)
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(delta >= 0 ? RTColor.optimal : RTColor.caution)
                                .monospacedDigit()
                        }
                        AnimatedSparkline(data: sparklineValues, color: reductionColor)
                            .frame(height: 28)
                            .accessibilityIdentifier(SurfaceID.envSoundReductionSpark)
                    }
                }

                if chartPoints.count >= 3 {
                    Chart {
                        ForEach(Array(chartPoints.enumerated()), id: \.offset) { _, point in
                            LineMark(
                                x: .value("Day", point.date),
                                y: .value("dBA", point.value)
                            )
                            .foregroundStyle(reductionColor)
                            .interpolationMethod(.catmullRom)

                            AreaMark(
                                x: .value("Day", point.date),
                                y: .value("dBA", point.value)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [reductionColor.opacity(0.22), reductionColor.opacity(0)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .interpolationMethod(.catmullRom)
                        }

                        RuleMark(y: .value("Good", 12))
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
                    .accessibilityLabel("Sound reduction trend last seven days")
                }
            }
            .padding(16)
        }
        .accessibilityIdentifier(SurfaceID.envSoundReductionCard)
    }

    private var yDomain: ClosedRange<Double> {
        let vals = chartPoints.map(\.value) + [base, tonight ?? base, 70].filter { $0 > 0 }
        let lo = max(0, (vals.min() ?? 5) - 3)
        let hi = max(lo + 15, (vals.max() ?? 25) + 5)
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

enum EnvSoundReductionBaseline {
    static func average(
        from history: [DailyHealthData],
        window: Int = 7,
        fallback: Double
    ) -> Double {
        let values = history
            .sorted { $0.date > $1.date }
            .prefix(window)
            .compactMap(\.environmentalSoundReductionDBA)
            .filter { $0 > 0 }
        guard !values.isEmpty else { return fallback }
        return values.reduce(0, +) / Double(values.count)
    }
}
