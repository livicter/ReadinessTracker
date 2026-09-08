import SwiftUI
import Charts

/// WHOOP-style respiratory rate: Tonight vs Baseline dual callout,
/// % delta, ±10% baseline band on the trend chart, and a compact 7-night sparkline.
struct RespiratoryRateCard: View {
    let currentRate: Double      // breaths per minute
    let history: [(date: Date, value: Double)]
    let baseline: Double

    private var deviation: Double {
        guard baseline > 0 else { return 0 }
        return ((currentRate - baseline) / baseline) * 100
    }

    private var bpmDelta: Double { currentRate - baseline }

    private var status: (label: String, color: Color) {
        let absDev = abs(deviation)
        // Lower RR vs baseline is often healthier; elevated is caution/warning.
        if absDev < 5 { return ("Normal", RTColor.optimal) }
        if absDev < 15 {
            return (deviation > 0 ? "Slightly Elevated" : "Slightly Low", RTColor.caution)
        }
        return (deviation > 0 ? "Elevated" : "Low", RTColor.warning)
    }

    /// Last 7 nights (oldest → newest) for sparkline glance.
    private var sparklineValues: [Double] {
        let sorted = history.sorted { $0.date < $1.date }
        return Array(sorted.suffix(7).map(\.value))
    }

    /// ±10% personal band around baseline (WHOOP-like “in range” zone).
    private var bandLow: Double { baseline * 0.90 }
    private var bandHigh: Double { baseline * 1.10 }

    private var chartPoints: [(date: Date, value: Double)] {
        history.sorted { $0.date < $1.date }
    }

    var body: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 14) {
                // Header
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Respiratory Rate")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(RTColor.primaryText)

                        Text("Breaths/min · \(status.label)")
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

                // WHOOP-like Tonight | Baseline dual metric
                HStack(spacing: 12) {
                    dualColumn(
                        label: "Tonight",
                        value: currentRate,
                        color: status.color,
                        caption: deltaCaption
                    )

                    Rectangle()
                        .fill(RTColor.divider)
                        .frame(width: 1)
                        .padding(.vertical, 4)

                    dualColumn(
                        label: "Baseline",
                        value: baseline,
                        color: RTColor.secondaryText,
                        caption: "personal average"
                    )
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier(SurfaceID.respiratoryBaselineCallout)

                // Compact 7-night sparkline
                if sparklineValues.count >= 2 {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("7-Night RR")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(RTColor.secondaryText)
                            Spacer()
                            Text(deltaCaption)
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(bpmDelta > 0 ? RTColor.warning : RTColor.optimal)
                                .monospacedDigit()
                        }
                        AnimatedSparkline(data: sparklineValues, color: RTColor.respiratory)
                            .frame(height: 28)
                            .accessibilityIdentifier(SurfaceID.respiratorySpark)
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
                            .foregroundStyle(RTColor.respiratory.opacity(0.10))
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
                                y: .value("Rate", point.value)
                            )
                            .foregroundStyle(RTColor.respiratory)
                            .lineStyle(StrokeStyle(lineWidth: 2))
                            .interpolationMethod(.catmullRom)

                            AreaMark(
                                x: .value("Date", point.date, unit: .day),
                                yStart: .value("Floor", min(bandLow, chartPoints.map(\.value).min() ?? 0) * 0.92),
                                yEnd: .value("Rate", point.value)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [RTColor.respiratory.opacity(0.14), RTColor.respiratory.opacity(0)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .interpolationMethod(.catmullRom)

                            if Calendar.current.isDateInToday(point.date) {
                                PointMark(
                                    x: .value("Date", point.date, unit: .day),
                                    y: .value("Rate", point.value)
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
                    .accessibilityLabel("Respiratory rate trend with baseline band")
                }

                if abs(deviation) > 10 {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(RTColor.caution)

                        Text(deviation > 0
                             ? "Elevated respiratory rate may indicate your body is working harder to recover."
                             : "Lower than usual respiratory rate. This can be positive if you feel well-rested.")
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
        .accessibilityIdentifier(SurfaceID.respiratoryCard)
        .accessibilityLabel("Respiratory Rate")
    }

    private var deltaCaption: String {
        let sign = bpmDelta >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", bpmDelta)) vs baseline"
    }

    private var yDomain: ClosedRange<Double> {
        let values = chartPoints.map(\.value) + [bandLow, bandHigh, baseline]
        let lo = (values.min() ?? 0) * 0.92
        let hi = (values.max() ?? 20) * 1.08
        return lo...max(hi, lo + 0.5)
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
                Text(String(format: "%.1f", value))
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
        .accessibilityLabel("\(label) \(String(format: "%.1f", value)) breaths per minute")
    }
}
