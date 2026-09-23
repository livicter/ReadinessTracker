import SwiftUI
import Charts

/// WHOOP-style resting heart rate: Tonight vs Baseline dual callout,
/// % delta, ±5% baseline band on the trend chart, and a compact 7-night sparkline.
/// Elevates the thinner Metrics MetricCard into the Today vitals stack.
struct RestingHRCard: View {
    let currentBPM: Double
    let history: [(date: Date, value: Double)]
    let baseline: Double

    private var deviation: Double {
        guard baseline > 0 else { return 0 }
        return ((currentBPM - baseline) / baseline) * 100
    }

    private var bpmDelta: Double { currentBPM - baseline }

    private var status: (label: String, color: Color) {
        let absDev = abs(deviation)
        // Lower RHR vs baseline is typically healthier; elevated is caution/warning.
        if absDev < 5 { return ("Optimal", RTColor.optimal) }
        if absDev < 12 {
            return (deviation > 0 ? "Slightly Elevated" : "Recovered", RTColor.caution)
        }
        return (deviation > 0 ? "Elevated" : "Low", RTColor.warning)
    }

    /// Last 7 nights (oldest → newest) for sparkline glance.
    private var sparklineValues: [Double] {
        let sorted = history.sorted { $0.date < $1.date }
        return Array(sorted.suffix(7).map(\.value))
    }

    /// ±5% personal band around baseline (tighter than RR — RHR is more stable).
    private var bandLow: Double { baseline * 0.95 }
    private var bandHigh: Double { baseline * 1.05 }

    private var chartPoints: [(date: Date, value: Double)] {
        history.sorted { $0.date < $1.date }
    }

    private var deltaCaption: String {
        let sign = bpmDelta >= 0 ? "+" : ""
        return "\(sign)\(Int(bpmDelta.rounded())) bpm vs baseline"
    }

    private var yDomain: ClosedRange<Double> {
        let values = chartPoints.map(\.value) + [bandLow, bandHigh, baseline]
        let lo = (values.min() ?? 40) * 0.94
        let hi = (values.max() ?? 80) * 1.06
        return lo...max(hi, lo + 1)
    }

    var body: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Resting Heart Rate")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(RTColor.primaryText)

                        Text("Beats/min · \(status.label)")
                            .font(.subheadline)
                            .foregroundStyle(status.color)
                    }

                    Spacer()

                    let sign = deviation >= 0 ? "+" : ""
                    Text("\(sign)\(Int(deviation.rounded()))%")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(status.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(status.color.opacity(0.12))
                        .clipShape(Capsule())
                        .accessibilityLabel("\(sign)\(Int(deviation.rounded())) percent versus baseline")
                }

                HStack(spacing: 12) {
                    dualColumn(
                        label: "Tonight",
                        value: currentBPM,
                        color: status.color,
                        caption: deltaCaption,
                        icon: "heart.fill"
                    )

                    Rectangle()
                        .fill(RTColor.divider)
                        .frame(width: 1)
                        .padding(.vertical, 4)

                    dualColumn(
                        label: "Baseline",
                        value: baseline,
                        color: RTColor.secondaryText,
                        caption: "personal average",
                        icon: "chart.line.flattrend.xyaxis"
                    )
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier(SurfaceID.restingHRBaselineCallout)

                if sparklineValues.count >= 2 {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("7-Night RHR")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(RTColor.secondaryText)
                            Spacer()
                            Text(deltaCaption)
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(bpmDelta > 2 ? RTColor.warning : RTColor.optimal)
                                .monospacedDigit()
                        }
                        AnimatedSparkline(data: sparklineValues, color: RTColor.strain)
                            .frame(height: 28)
                            .accessibilityIdentifier(SurfaceID.restingHRSpark)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                if chartPoints.count >= 2 {
                    Chart {
                        ForEach(chartPoints, id: \.date) { point in
                            AreaMark(
                                x: .value("Date", point.date, unit: .day),
                                yStart: .value("BandLow", bandLow),
                                yEnd: .value("BandHigh", bandHigh)
                            )
                            .foregroundStyle(RTColor.strain.opacity(0.10))
                            .interpolationMethod(.linear)
                        }

                        RuleMark(y: .value("Baseline", baseline))
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
                                y: .value("RHR", point.value)
                            )
                            .foregroundStyle(RTColor.strain)
                            .lineStyle(StrokeStyle(lineWidth: 2))
                            .interpolationMethod(.catmullRom)

                            AreaMark(
                                x: .value("Date", point.date, unit: .day),
                                yStart: .value("Floor", min(bandLow, chartPoints.map(\.value).min() ?? 40) * 0.94),
                                yEnd: .value("RHR", point.value)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [RTColor.strain.opacity(0.14), RTColor.strain.opacity(0)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .interpolationMethod(.catmullRom)

                            if Calendar.current.isDateInToday(point.date) {
                                PointMark(
                                    x: .value("Date", point.date, unit: .day),
                                    y: .value("RHR", point.value)
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
                    .accessibilityLabel("Resting heart rate trend with baseline band")
                }

                if abs(deviation) > 8 {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(RTColor.caution)
                            .frame(width: 26, height: 26)
                            .background(RTColor.caution.opacity(0.14))
                            .clipShape(Circle())
                            .accessibilityHidden(true)

                        Text(deviation > 0
                             ? "Elevated resting HR can signal incomplete recovery, illness, or stress."
                             : "Lower than usual resting HR often tracks with better recovery when you feel well.")
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
        .accessibilityIdentifier(SurfaceID.restingHRCard)
    }

    private func dualColumn(
        label: String,
        value: Double,
        color: Color,
        caption: String,
        icon: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(width: 22, height: 22)
                    .background(color.opacity(0.14))
                    .clipShape(Circle())
                    .accessibilityHidden(true)
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
            }

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(Int(value.rounded()))")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
                    .monospacedDigit()
                Text("bpm")
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
        .accessibilityLabel("\(label) \(Int(value.rounded())) beats per minute")
    }
}
