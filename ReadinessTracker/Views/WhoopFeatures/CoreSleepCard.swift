import SwiftUI
import Charts

/// WHOOP / Apple Health–style Core (Light) sleep hours: Tonight vs Baseline dual callout
/// from `lightSleepPercent × sleepHours`, Abundant / Solid / Fair / Low band, and a
/// compact 7-night sparkline. Completes stage-hour elevation after Restorative Deep|REM.
struct CoreSleepCard: View {
    let sleepHours: Double
    let lightPercent: Double
    /// Prior nights: (date, sleepHours, lightPercent).
    let history: [(date: Date, sleepHours: Double, lightPercent: Double)]
    let baselineHours: Double

    private var tonight: Double {
        CoreSleep.hours(asleep: sleepHours, lightPercent: lightPercent)
    }

    private var base: Double {
        let b = baselineHours > 0 ? baselineHours : tonight
        return max(0, b)
    }

    private var deltaHours: Double { tonight - base }

    private var lightFraction: Double { CoreSleep.asFraction(lightPercent) }

    private var status: (label: String, color: Color) {
        // Core is typically the largest stage share (~45–55% of asleep time).
        if lightFraction >= 0.55 { return ("Abundant", RTColor.optimal) }
        if lightFraction >= 0.45 { return ("Solid", RTColor.good) }
        if lightFraction >= 0.35 { return ("Fair", RTColor.caution) }
        return ("Low", RTColor.warning)
    }

    private var sparklineValues: [Double] {
        let sorted = history.sorted { $0.date < $1.date }
        return Array(sorted.suffix(7).map {
            CoreSleep.hours(asleep: $0.sleepHours, lightPercent: $0.lightPercent)
        })
    }

    private var chartPoints: [(date: Date, value: Double)] {
        history.sorted { $0.date < $1.date }.map {
            (date: $0.date, value: CoreSleep.hours(asleep: $0.sleepHours, lightPercent: $0.lightPercent))
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
        "\(Int((lightFraction * 100).rounded()))% of night"
    }

    var body: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Core Sleep")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(RTColor.primaryText)

                        Text("Light / Core hours · \(status.label)")
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
                        .accessibilityLabel("\(hoursText(tonight)) hours core sleep, \(status.label)")
                }

                HStack(spacing: 12) {
                    dualColumn(
                        label: "Tonight",
                        valueText: hoursText(tonight),
                        unit: "h",
                        color: status.color,
                        caption: percentCaption,
                        icon: "zzz"
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
                .accessibilityIdentifier(SurfaceID.coreSleepBaselineCallout)

                if sparklineValues.count >= 2 {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("7-Night Core")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(RTColor.secondaryText)
                            Spacer()
                            Text(deltaCaption)
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(deltaHours < -0.4 ? RTColor.caution : RTColor.optimal)
                                .monospacedDigit()
                        }
                        AnimatedSparkline(data: sparklineValues, color: Color(hex: "5E5CE6"))
                            .frame(height: 28)
                            .accessibilityIdentifier(SurfaceID.coreSleepSpark)
                    }
                }

                if chartPoints.count >= 3 {
                    Chart {
                        ForEach(Array(chartPoints.enumerated()), id: \.offset) { _, point in
                            LineMark(
                                x: .value("Night", point.date),
                                y: .value("Hours", point.value)
                            )
                            .foregroundStyle(Color(hex: "5E5CE6"))
                            .interpolationMethod(.catmullRom)

                            AreaMark(
                                x: .value("Night", point.date),
                                y: .value("Hours", point.value)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "5E5CE6").opacity(0.18), Color(hex: "5E5CE6").opacity(0)],
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
                    .chartYScale(domain: 0...(max(5.0, (chartPoints.map(\.value).max() ?? 4) * 1.2)))
                    .chartXAxis(.hidden)
                    .chartYAxis {
                        AxisMarks(position: .leading, values: [2, 3, 4]) { value in
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
                    .accessibilityLabel("Core sleep trend last nights")
                }
            }
            .padding(16)
        }
        .accessibilityIdentifier(SurfaceID.coreSleepCard)
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

enum CoreSleep {
    static func asFraction(_ lightPercent: Double) -> Double {
        lightPercent > 1.5 ? min(1, max(0, lightPercent / 100)) : min(1, max(0, lightPercent))
    }

    /// Core / light hours = asleep × lightSleepPercent.
    static func hours(asleep: Double, lightPercent: Double) -> Double {
        max(0, asleep) * asFraction(lightPercent)
    }

    static func baseline(
        from history: [DailyHealthData],
        window: Int = 7,
        fallback: Double
    ) -> Double {
        let values = history
            .sorted { $0.date > $1.date }
            .prefix(window)
            .map { hours(asleep: $0.sleepHours, lightPercent: $0.lightSleepPercent) }
            .filter { $0 > 0 }
        guard !values.isEmpty else { return fallback }
        return values.reduce(0, +) / Double(values.count)
    }
}
