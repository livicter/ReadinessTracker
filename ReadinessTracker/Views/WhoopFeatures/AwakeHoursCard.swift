import SwiftUI
import Charts

/// WHOOP / Apple Health–style awake hours: Tonight vs Baseline dual callout
/// from `awakePercent × timeInBed` (same as Sleep Analysis / Day Detail),
/// Minimal / Light / Notable / High band, and a compact 7-night sparkline.
/// Distinct from Wake Episodes (count) and Sleep Latency (onset minutes).
struct AwakeHoursCard: View {
    let sleepHours: Double
    let sleepEfficiency: Double
    let awakePercent: Double
    /// Prior nights: (date, sleepHours, sleepEfficiency, awakePercent).
    let history: [(date: Date, sleepHours: Double, sleepEfficiency: Double, awakePercent: Double)]
    let baselineHours: Double

    private var tonight: Double {
        AwakeHours.hours(
            asleep: sleepHours,
            efficiency: sleepEfficiency,
            awakePercent: awakePercent
        )
    }

    private var base: Double {
        let b = baselineHours > 0 ? baselineHours : tonight
        return max(0, b)
    }

    private var deltaHours: Double { tonight - base }

    private var status: (label: String, color: Color) {
        // Lower awake duration is better (Sleep Analysis: <5% of in-bed is optimal).
        if tonight < 0.25 { return ("Minimal", RTColor.optimal) }
        if tonight < 0.50 { return ("Light", RTColor.good) }
        if tonight < 1.00 { return ("Notable", RTColor.caution) }
        return ("High", RTColor.warning)
    }

    private var sparklineValues: [Double] {
        let sorted = history.sorted { $0.date < $1.date }
        return Array(sorted.suffix(7).map {
            AwakeHours.hours(
                asleep: $0.sleepHours,
                efficiency: $0.sleepEfficiency,
                awakePercent: $0.awakePercent
            )
        })
    }

    private var chartPoints: [(date: Date, value: Double)] {
        history.sorted { $0.date < $1.date }.map {
            (
                date: $0.date,
                value: AwakeHours.hours(
                    asleep: $0.sleepHours,
                    efficiency: $0.sleepEfficiency,
                    awakePercent: $0.awakePercent
                )
            )
        }
    }

    private func hoursText(_ hours: Double) -> String {
        String(format: "%.1f", hours)
    }

    private var deltaCaption: String {
        let sign = deltaHours >= 0 ? "+" : ""
        return "\(sign)\(hoursText(deltaHours))h vs baseline"
    }

    private var percentCaption: String {
        let frac = AwakeHours.asFraction(awakePercent)
        return "\(Int((frac * 100).rounded()))% of in-bed"
    }

    var body: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Awake Hours")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(RTColor.primaryText)

                        Text("In-bed awake · \(status.label)")
                            .font(.subheadline)
                            .foregroundStyle(status.color)
                    }

                    Spacer()

                    Text(hoursText(tonight) + "h")
                        .font(.title2.weight(.bold).monospacedDigit())
                        .foregroundStyle(status.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(status.color.opacity(0.12))
                        .clipShape(Capsule())
                        .accessibilityLabel("\(hoursText(tonight)) hours awake, \(status.label)")
                }

                HStack(spacing: 12) {
                    dualColumn(
                        label: "Tonight",
                        valueText: hoursText(tonight),
                        unit: "h",
                        color: status.color,
                        caption: percentCaption,
                        icon: "eye.fill"
                    )

                    Rectangle()
                        .fill(RTColor.divider)
                        .frame(width: 1)
                        .padding(.vertical, 4)

                    dualColumn(
                        label: "Baseline",
                        valueText: hoursText(base),
                        unit: "h",
                        color: RTColor.secondaryText,
                        caption: "7-night average",
                        icon: "chart.line.flattrend.xyaxis"
                    )
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier(SurfaceID.awakeHoursBaselineCallout)

                if sparklineValues.count >= 2 {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("7-Night Awake")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(RTColor.secondaryText)
                            Spacer()
                            Text(deltaCaption)
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(deltaHours > 0.15 ? RTColor.caution : RTColor.optimal)
                                .monospacedDigit()
                        }
                        AnimatedSparkline(data: sparklineValues, color: RTColor.caution)
                            .frame(height: 28)
                            .accessibilityIdentifier(SurfaceID.awakeHoursSpark)
                    }
                }

                if chartPoints.count >= 3 {
                    Chart {
                        ForEach(Array(chartPoints.enumerated()), id: \.offset) { _, point in
                            LineMark(
                                x: .value("Night", point.date),
                                y: .value("Hours", point.value)
                            )
                            .foregroundStyle(RTColor.caution)
                            .interpolationMethod(.catmullRom)

                            AreaMark(
                                x: .value("Night", point.date),
                                y: .value("Hours", point.value)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [RTColor.caution.opacity(0.18), RTColor.caution.opacity(0)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .interpolationMethod(.catmullRom)
                        }

                        RuleMark(y: .value("Light", 0.5))
                            .foregroundStyle(RTColor.secondaryText.opacity(0.35))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    }
                    .chartYScale(domain: 0...(max(1.2, (chartPoints.map(\.value).max() ?? 0.5) * 1.35)))
                    .chartXAxis(.hidden)
                    .chartYAxis {
                        AxisMarks(position: .leading, values: [0.25, 0.5, 1.0]) { value in
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
                    .accessibilityLabel("Awake hours trend last nights")
                }
            }
            .padding(16)
        }
        .accessibilityIdentifier(SurfaceID.awakeHoursCard)
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

enum AwakeHours {
    static func asFraction(_ awakePercent: Double) -> Double {
        awakePercent > 1.5 ? min(1, max(0, awakePercent / 100)) : min(1, max(0, awakePercent))
    }

    /// Awake hours = timeInBed × awakePercent (Sleep Analysis / Day Detail).
    static func hours(asleep: Double, efficiency: Double, awakePercent: Double) -> Double {
        let inBed = TimeInBed.hours(asleep: asleep, efficiency: efficiency)
        return max(0, inBed * asFraction(awakePercent))
    }

    static func baseline(
        from history: [DailyHealthData],
        window: Int = 7,
        fallback: Double
    ) -> Double {
        let values = history
            .sorted { $0.date > $1.date }
            .prefix(window)
            .map {
                hours(
                    asleep: $0.sleepHours,
                    efficiency: $0.sleepEfficiency,
                    awakePercent: $0.awakePercent
                )
            }
            .filter { $0 >= 0 }
        guard !values.isEmpty else { return fallback }
        return values.reduce(0, +) / Double(values.count)
    }
}
