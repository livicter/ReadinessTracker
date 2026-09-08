import SwiftUI
import Charts

/// WHOOP-style skin temperature: Tonight vs Baseline dual callout,
/// °C delta, ±0.3°C baseline band on the trend chart, and a compact 7-night sparkline.
struct SkinTemperatureCard: View {
    let currentTemp: Double      // Current skin temp in Celsius
    let baselineTemp: Double     // Personal baseline
    let history: [(date: Date, value: Double)]

    private var deviation: Double {
        currentTemp - baselineTemp
    }

    private var status: (label: String, color: Color) {
        let absDev = abs(deviation)
        if absDev < 0.3 { return ("Normal", RTColor.optimal) }
        if absDev < 0.8 {
            return (deviation > 0 ? "Elevated" : "Low", RTColor.caution)
        }
        return (deviation > 0 ? "Significantly Elevated" : "Significantly Low", RTColor.warning)
    }

    /// Last 7 nights (oldest → newest) for sparkline glance.
    private var sparklineValues: [Double] {
        let sorted = history.sorted { $0.date < $1.date }
        return Array(sorted.suffix(7).map(\.value))
    }

    /// ±0.3°C personal band around baseline (WHOOP-like “in range” zone).
    private var bandLow: Double { baselineTemp - 0.3 }
    private var bandHigh: Double { baselineTemp + 0.3 }

    private var chartPoints: [(date: Date, value: Double)] {
        history.sorted { $0.date < $1.date }
    }

    var body: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 14) {
                // Header
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Skin Temperature")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(RTColor.primaryText)

                        Text("Nightly · \(status.label)")
                            .font(.subheadline)
                            .foregroundStyle(status.color)
                    }

                    Spacer()

                    let sign = deviation >= 0 ? "+" : ""
                    Text("\(sign)\(String(format: "%.2f", deviation))°C")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(status.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(status.color.opacity(0.12))
                        .clipShape(Capsule())
                        .accessibilityLabel("\(sign)\(String(format: "%.2f", deviation)) degrees Celsius versus baseline")
                }

                // WHOOP-like Tonight | Baseline dual metric
                HStack(spacing: 12) {
                    dualColumn(
                        label: "Tonight",
                        value: currentTemp,
                        color: status.color,
                        caption: deltaCaption
                    )

                    Rectangle()
                        .fill(RTColor.divider)
                        .frame(width: 1)
                        .padding(.vertical, 4)

                    dualColumn(
                        label: "Baseline",
                        value: baselineTemp,
                        color: RTColor.secondaryText,
                        caption: "personal average"
                    )
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier(SurfaceID.skinTempBaselineCallout)

                // Compact 7-night sparkline
                if sparklineValues.count >= 2 {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("7-Night Temp")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(RTColor.secondaryText)
                            Spacer()
                            Text(deltaCaption)
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(abs(deviation) < 0.3 ? RTColor.optimal : RTColor.caution)
                                .monospacedDigit()
                        }
                        AnimatedSparkline(data: sparklineValues, color: RTColor.skinTemp)
                            .frame(height: 28)
                            .accessibilityIdentifier(SurfaceID.skinTempSpark)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Trend chart with baseline band
                if chartPoints.count >= 2 {
                    Chart {
                        ForEach(chartPoints, id: \.date) { point in
                            AreaMark(
                                x: .value("Date", point.date, unit: .day),
                                yStart: .value("BandLow", bandLow),
                                yEnd: .value("BandHigh", bandHigh)
                            )
                            .foregroundStyle(RTColor.skinTemp.opacity(0.10))
                            .interpolationMethod(.linear)
                        }

                        RuleMark(y: .value("Baseline", baselineTemp))
                            .foregroundStyle(RTColor.primaryText.opacity(0.28))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                            .annotation(position: .top, alignment: .trailing) {
                                Text("Baseline")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundStyle(RTColor.tertiaryText)
                                    .padding(.trailing, 2)
                            }

                        ForEach(chartPoints, id: \.date) { point in
                            LineMark(
                                x: .value("Date", point.date, unit: .day),
                                y: .value("Temp", point.value)
                            )
                            .foregroundStyle(RTColor.skinTemp)
                            .lineStyle(StrokeStyle(lineWidth: 2))
                            .interpolationMethod(.catmullRom)

                            AreaMark(
                                x: .value("Date", point.date, unit: .day),
                                yStart: .value("Floor", min(bandLow, chartPoints.map(\.value).min() ?? 0) - 0.15),
                                yEnd: .value("Temp", point.value)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [RTColor.skinTemp.opacity(0.14), RTColor.skinTemp.opacity(0)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .interpolationMethod(.catmullRom)

                            if Calendar.current.isDateInToday(point.date) {
                                PointMark(
                                    x: .value("Date", point.date, unit: .day),
                                    y: .value("Temp", point.value)
                                )
                                .foregroundStyle(status.color)
                                .symbolSize(80)
                            }
                        }
                    }
                    .frame(height: 120)
                    .chartYScale(domain: yDomain)
                    .chartYAxis {
                        AxisMarks { _ in
                            AxisGridLine().foregroundStyle(RTColor.divider)
                            AxisValueLabel()
                                .font(.system(size: 9))
                                .foregroundStyle(RTColor.secondaryText)
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day)) { _ in
                            AxisGridLine().foregroundStyle(RTColor.divider)
                            AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                                .foregroundStyle(RTColor.secondaryText)
                        }
                    }
                    .accessibilityLabel("Skin temperature trend with baseline band")
                }

                if abs(deviation) > 0.5 {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(RTColor.caution)

                        Text(deviation > 0
                             ? "Elevated skin temperature can indicate your body is fighting something or recovering from intense strain."
                             : "Lower skin temperature may indicate better recovery or cooler environmental conditions.")
                            .font(.caption)
                            .foregroundStyle(RTColor.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer()
                    }
                    .padding(12)
                    .background(RTColor.caution.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: AppleTheme.cornerRadiusMedium, style: .continuous))
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(SurfaceID.skinTempCard)
        .accessibilityLabel("Skin Temperature")
    }

    private var deltaCaption: String {
        let sign = deviation >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", deviation))°C vs baseline"
    }

    private var yDomain: ClosedRange<Double> {
        let values = chartPoints.map(\.value) + [bandLow, bandHigh, baselineTemp]
        let lo = (values.min() ?? 36) - 0.2
        let hi = (values.max() ?? 37) + 0.2
        return lo...max(hi, lo + 0.4)
    }

    private func dualColumn(
        label: String,
        value: Double,
        color: Color,
        caption: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(RTColor.secondaryText)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(String(format: "%.2f", value))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
                    .monospacedDigit()
                Text("°C")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(RTColor.tertiaryText)
            }

            Text(caption)
                .font(.caption2)
                .foregroundStyle(RTColor.tertiaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label) \(String(format: "%.2f", value)) degrees Celsius")
    }
}
