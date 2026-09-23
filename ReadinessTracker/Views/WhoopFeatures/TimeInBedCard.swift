import SwiftUI
import Charts

/// WHOOP / Apple Health–style time in bed vs asleep: Tonight | Baseline dual callout
/// (each column stacks In Bed + Asleep hours), Efficient/Good/Fair/Poor band from
/// asleep÷in-bed, and a compact 7-night in-bed sparkline.
/// Elevates hours that Day Detail / Sleep Analysis already show but Today only
/// exposed via Need|Got and Efficiency %.
struct TimeInBedCard: View {
    let sleepHours: Double
    let sleepEfficiency: Double
    /// Prior nights: (date, sleepHours, sleepEfficiency).
    let history: [(date: Date, sleepHours: Double, sleepEfficiency: Double)]
    let baselineInBed: Double
    let baselineAsleep: Double

    private var tonightAsleep: Double { max(0, sleepHours) }
    private var tonightInBed: Double {
        TimeInBed.hours(asleep: sleepHours, efficiency: sleepEfficiency)
    }

    private var baseInBed: Double {
        let b = baselineInBed > 0 ? baselineInBed : tonightInBed
        return max(0, b)
    }

    private var baseAsleep: Double {
        let b = baselineAsleep > 0 ? baselineAsleep : tonightAsleep
        return max(0, b)
    }

    private var efficiencyFraction: Double {
        TimeInBed.asFraction(sleepEfficiency)
    }

    private var status: (label: String, color: Color) {
        let pct = efficiencyFraction * 100
        if pct >= 90 { return ("Efficient", RTColor.optimal) }
        if pct >= 85 { return ("Good", RTColor.good) }
        if pct >= 75 { return ("Fair", RTColor.caution) }
        return ("Poor", RTColor.warning)
    }

    private var gapTonight: Double { tonightInBed - tonightAsleep }

    private var deltaInBed: Double { tonightInBed - baseInBed }

    private var sparklineValues: [Double] {
        let sorted = history.sorted { $0.date < $1.date }
        return Array(sorted.suffix(7).map {
            TimeInBed.hours(asleep: $0.sleepHours, efficiency: $0.sleepEfficiency)
        })
    }

    private var chartPoints: [(date: Date, value: Double)] {
        history.sorted { $0.date < $1.date }.map {
            (date: $0.date, value: TimeInBed.hours(asleep: $0.sleepHours, efficiency: $0.sleepEfficiency))
        }
    }

    private func hoursText(_ hours: Double) -> String {
        String(format: "%.1f", hours)
    }

    private var deltaCaption: String {
        let sign = deltaInBed >= 0 ? "+" : ""
        return "\(sign)\(hoursText(deltaInBed))h vs baseline"
    }

    var body: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Time in Bed")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(RTColor.primaryText)

                        Text("In bed vs asleep · \(status.label)")
                            .font(.subheadline)
                            .foregroundStyle(status.color)
                    }

                    Spacer()

                    Text(hoursText(tonightInBed) + "h")
                        .font(.title2.weight(.bold).monospacedDigit())
                        .foregroundStyle(status.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(status.color.opacity(0.12))
                        .clipShape(Capsule())
                        .accessibilityLabel("\(hoursText(tonightInBed)) hours in bed, \(status.label)")
                }

                HStack(spacing: 12) {
                    nightColumn(
                        label: "Tonight",
                        inBed: tonightInBed,
                        asleep: tonightAsleep,
                        color: status.color,
                        caption: gapTonight >= 0.05
                            ? "\(hoursText(gapTonight))h awake/latency"
                            : deltaCaption,
                        icon: "bed.double.fill"
                    )

                    Rectangle()
                        .fill(RTColor.divider)
                        .frame(width: 1)
                        .padding(.vertical, 4)

                    nightColumn(
                        label: "Baseline",
                        inBed: baseInBed,
                        asleep: baseAsleep,
                        color: RTColor.secondaryText,
                        caption: "7-night average",
                        icon: "chart.line.flattrend.xyaxis"
                    )
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier(SurfaceID.timeInBedBaselineCallout)

                if sparklineValues.count >= 2 {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("7-Night In Bed")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(RTColor.secondaryText)
                            Spacer()
                            Text(deltaCaption)
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(abs(deltaInBed) > 0.4 ? RTColor.caution : RTColor.optimal)
                                .monospacedDigit()
                        }
                        AnimatedSparkline(data: sparklineValues, color: RTColor.sleep)
                            .frame(height: 28)
                            .accessibilityIdentifier(SurfaceID.timeInBedSpark)
                    }
                }

                if chartPoints.count >= 3 {
                    Chart {
                        ForEach(Array(chartPoints.enumerated()), id: \.offset) { _, point in
                            LineMark(
                                x: .value("Night", point.date),
                                y: .value("Hours", point.value)
                            )
                            .foregroundStyle(RTColor.sleep)
                            .interpolationMethod(.catmullRom)

                            AreaMark(
                                x: .value("Night", point.date),
                                y: .value("Hours", point.value)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [RTColor.sleep.opacity(0.18), RTColor.sleep.opacity(0)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .interpolationMethod(.catmullRom)
                        }

                        RuleMark(y: .value("Target", 8))
                            .foregroundStyle(RTColor.secondaryText.opacity(0.35))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    }
                    .chartYScale(domain: 0...(max(10.0, (chartPoints.map(\.value).max() ?? 8) * 1.15)))
                    .chartXAxis(.hidden)
                    .chartYAxis {
                        AxisMarks(position: .leading, values: [6, 8, 10]) { value in
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
                    .accessibilityLabel("Time in bed trend last nights")
                }
            }
            .padding(16)
        }
        .accessibilityIdentifier(SurfaceID.timeInBedCard)
    }

    private func nightColumn(
        label: String,
        inBed: Double,
        asleep: Double,
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

            VStack(alignment: .leading, spacing: 4) {
                metricRow(name: "In Bed", hours: inBed, emphasize: true)
                metricRow(name: "Asleep", hours: asleep, emphasize: false)
            }

            Text(caption)
                .font(.caption2)
                .foregroundStyle(RTColor.secondaryText)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func metricRow(name: String, hours: Double, emphasize: Bool) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(name)
                .font(.caption2.weight(.medium))
                .foregroundStyle(RTColor.secondaryText)
                .frame(width: 48, alignment: .leading)
            Text(hoursText(hours))
                .font((emphasize ? Font.title3 : Font.body).weight(.bold).monospacedDigit())
                .foregroundStyle(RTColor.primaryText)
            Text("h")
                .font(.caption.weight(.medium))
                .foregroundStyle(RTColor.secondaryText)
        }
    }
}

enum TimeInBed {
    /// Normalize efficiency to 0…1 whether stored as fraction or percent.
    static func asFraction(_ efficiency: Double) -> Double {
        efficiency > 1.5 ? min(1, max(0, efficiency / 100)) : min(1, max(0, efficiency))
    }

    /// Time in bed hours from asleep hours ÷ efficiency (same as Day Detail / Sleep Analysis).
    static func hours(asleep: Double, efficiency: Double) -> Double {
        let frac = asFraction(efficiency)
        guard asleep > 0, frac > 0.01 else { return max(0, asleep) }
        return asleep / frac
    }

    static func baselineInBed(
        from history: [DailyHealthData],
        window: Int = 7,
        fallback: Double
    ) -> Double {
        let values = history
            .sorted { $0.date > $1.date }
            .prefix(window)
            .map { hours(asleep: $0.sleepHours, efficiency: $0.sleepEfficiency) }
            .filter { $0 > 0 }
        guard !values.isEmpty else { return fallback }
        return values.reduce(0, +) / Double(values.count)
    }

    static func baselineAsleep(
        from history: [DailyHealthData],
        window: Int = 7,
        fallback: Double
    ) -> Double {
        let values = history
            .sorted { $0.date > $1.date }
            .prefix(window)
            .map(\.sleepHours)
            .filter { $0 > 0 }
        guard !values.isEmpty else { return fallback }
        return values.reduce(0, +) / Double(values.count)
    }
}
