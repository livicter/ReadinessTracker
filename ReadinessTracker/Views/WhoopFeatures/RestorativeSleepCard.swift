import SwiftUI
import Charts

/// WHOOP / Apple Health–style restorative sleep: Deep | REM dual callout in hours
/// (from existing stage %), Rich/Solid/Fair/Low band, and a 7-night restorative spark.
struct RestorativeSleepCard: View {
    let sleepHours: Double
    let deepPercent: Double
    let remPercent: Double
    /// Prior nights for spark: (date, sleepHours, deepPercent, remPercent).
    let history: [(date: Date, sleepHours: Double, deepPercent: Double, remPercent: Double)]

    private func asFraction(_ value: Double) -> Double {
        // Accept fraction (0.17) or already-percent (17).
        value > 1.5 ? min(1, max(0, value / 100)) : min(1, max(0, value))
    }

    private var deepHours: Double { max(0, sleepHours) * asFraction(deepPercent) }
    private var remHours: Double { max(0, sleepHours) * asFraction(remPercent) }
    private var restorativeHours: Double { deepHours + remHours }

    private var restorativeFraction: Double {
        guard sleepHours > 0 else { return 0 }
        return restorativeHours / sleepHours
    }

    private var status: (label: String, color: Color) {
        // Combined Deep+REM share of asleep time (WHOOP restorative zone ~35–45%).
        if restorativeFraction >= 0.40 { return ("Rich", RTColor.optimal) }
        if restorativeFraction >= 0.35 { return ("Solid", RTColor.good) }
        if restorativeFraction >= 0.28 { return ("Fair", RTColor.caution) }
        return ("Low", RTColor.warning)
    }

    private func hoursText(_ hours: Double) -> String {
        String(format: "%.1f", hours)
    }

    private func percentCaption(_ fraction: Double) -> String {
        "\(Int((asFraction(fraction) * 100).rounded()))% of night"
    }

    private var sparklineValues: [Double] {
        let sorted = history.sorted { $0.date < $1.date }
        return Array(sorted.suffix(7).map {
            max(0, $0.sleepHours) * (asFraction($0.deepPercent) + asFraction($0.remPercent))
        })
    }

    private var chartPoints: [(date: Date, value: Double)] {
        history.sorted { $0.date < $1.date }.map {
            (date: $0.date, value: max(0, $0.sleepHours) * (asFraction($0.deepPercent) + asFraction($0.remPercent)))
        }
    }

    var body: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Restorative Sleep")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(RTColor.primaryText)

                        Text("Deep + REM · \(status.label)")
                            .font(.subheadline)
                            .foregroundStyle(status.color)
                    }

                    Spacer()

                    Text(hoursText(restorativeHours) + "h")
                        .font(.title2.weight(.bold).monospacedDigit())
                        .foregroundStyle(status.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(status.color.opacity(0.12))
                        .clipShape(Capsule())
                        .accessibilityLabel("\(hoursText(restorativeHours)) hours restorative sleep, \(status.label)")
                }

                HStack(spacing: 12) {
                    dualColumn(
                        label: "Deep",
                        valueText: hoursText(deepHours),
                        unit: "h",
                        color: RTColor.sleep,
                        caption: percentCaption(deepPercent),
                        icon: "moon.stars.fill"
                    )

                    Rectangle()
                        .fill(RTColor.divider)
                        .frame(width: 1)
                        .padding(.vertical, 4)

                    dualColumn(
                        label: "REM",
                        valueText: hoursText(remHours),
                        unit: "h",
                        color: RTColor.consistency,
                        caption: percentCaption(remPercent),
                        icon: "sparkles"
                    )
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier(SurfaceID.sleepRestorativeDual)

                if sparklineValues.count >= 2 {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("7-Night Restorative")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(RTColor.secondaryText)
                            Spacer()
                            Text("\(hoursText(restorativeHours))h tonight")
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(status.color)
                                .monospacedDigit()
                        }
                        AnimatedSparkline(data: sparklineValues, color: RTColor.sleep)
                            .frame(height: 28)
                            .accessibilityIdentifier(SurfaceID.sleepRestorativeSpark)
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

                        RuleMark(y: .value("Solid", 2.5))
                            .foregroundStyle(RTColor.secondaryText.opacity(0.35))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    }
                    .chartYScale(domain: 0...(max(4.0, (chartPoints.map(\.value).max() ?? 3) * 1.2)))
                    .chartXAxis(.hidden)
                    .chartYAxis {
                        AxisMarks(position: .leading, values: [1, 2, 3]) { value in
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
                    .accessibilityLabel("Restorative sleep trend last nights")
                }
            }
            .padding(16)
        }
        .accessibilityIdentifier(SurfaceID.sleepRestorativeCard)
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
