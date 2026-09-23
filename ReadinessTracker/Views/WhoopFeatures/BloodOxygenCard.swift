import SwiftUI
import Charts

/// WHOOP / Google Health–style blood oxygen: Tonight vs Baseline dual callout,
/// pp delta, ±1% baseline band on the trend chart, and a compact 7-night sparkline.
struct BloodOxygenCard: View {
    let currentSpO2: Double      // percent (e.g. 97)
    let history: [(date: Date, value: Double)]
    let baseline: Double

    /// Normalize 0–1 fractions into percent for display.
    private var tonight: Double { currentSpO2 > 1.5 ? currentSpO2 : currentSpO2 * 100 }
    private var base: Double {
        let b = baseline > 1.5 ? baseline : baseline * 100
        return b > 0 ? b : tonight
    }

    private var deviationPP: Double { tonight - base }

    private var status: (label: String, color: Color) {
        // Absolute SpO2 first (clinical-ish soft bands), then vs baseline.
        if tonight < 92 { return ("Low", RTColor.warning) }
        if tonight < 95 { return ("Below Typical", RTColor.caution) }
        let absDev = abs(deviationPP)
        if absDev < 1 { return ("Normal", RTColor.optimal) }
        if absDev < 2 {
            return (deviationPP < 0 ? "Slightly Low" : "Slightly High", RTColor.caution)
        }
        return (deviationPP < 0 ? "Low vs Baseline" : "High vs Baseline",
                deviationPP < 0 ? RTColor.warning : RTColor.caution)
    }

    private var sparklineValues: [Double] {
        let sorted = history.sorted { $0.date < $1.date }
        return Array(sorted.suffix(7).map { $0.value > 1.5 ? $0.value : $0.value * 100 })
    }

    /// ±1 percentage-point personal band around baseline.
    private var bandLow: Double { base - 1 }
    private var bandHigh: Double { base + 1 }

    private var chartPoints: [(date: Date, value: Double)] {
        history.sorted { $0.date < $1.date }.map {
            (date: $0.date, value: $0.value > 1.5 ? $0.value : $0.value * 100)
        }
    }

    private var deltaCaption: String {
        let sign = deviationPP >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", deviationPP)) pp vs baseline"
    }

    var body: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Blood Oxygen")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(RTColor.primaryText)

                        Text("SpO₂ · \(status.label)")
                            .font(.subheadline)
                            .foregroundStyle(status.color)
                    }

                    Spacer()

                    let sign = deviationPP >= 0 ? "+" : ""
                    Text("\(sign)\(String(format: "%.1f", deviationPP))%")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(status.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(status.color.opacity(0.12))
                        .clipShape(Capsule())
                        .accessibilityLabel("\(sign)\(String(format: "%.1f", deviationPP)) percentage points versus baseline")
                }

                HStack(spacing: 12) {
                    dualColumn(
                        label: "Tonight",
                        value: tonight,
                        color: status.color,
                        caption: deltaCaption,
                        icon: "lungs.fill"
                    )

                    Rectangle()
                        .fill(RTColor.divider)
                        .frame(width: 1)
                        .padding(.vertical, 4)

                    dualColumn(
                        label: "Baseline",
                        value: base,
                        color: RTColor.secondaryText,
                        caption: "personal average",
                        icon: "chart.line.flattrend.xyaxis"
                    )
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier(SurfaceID.bloodOxygenBaselineCallout)

                if sparklineValues.count >= 2 {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("7-Night SpO₂")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(RTColor.secondaryText)
                            Spacer()
                            Text(deltaCaption)
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(deviationPP < -1 ? RTColor.warning : RTColor.optimal)
                                .monospacedDigit()
                        }
                        AnimatedSparkline(data: sparklineValues, color: RTColor.optimal)
                            .frame(height: 28)
                            .accessibilityIdentifier(SurfaceID.bloodOxygenSpark)
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
                            .foregroundStyle(RTColor.optimal.opacity(0.10))
                            .interpolationMethod(.linear)
                        }

                        RuleMark(y: .value("Baseline", base))
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
                                y: .value("SpO2", point.value)
                            )
                            .foregroundStyle(RTColor.optimal)
                            .lineStyle(StrokeStyle(lineWidth: 2))
                            .interpolationMethod(.catmullRom)

                            AreaMark(
                                x: .value("Date", point.date, unit: .day),
                                yStart: .value("Floor", yDomain.lowerBound),
                                yEnd: .value("SpO2", point.value)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [RTColor.optimal.opacity(0.14), RTColor.optimal.opacity(0)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .interpolationMethod(.catmullRom)

                            if Calendar.current.isDateInToday(point.date) {
                                PointMark(
                                    x: .value("Date", point.date, unit: .day),
                                    y: .value("SpO2", point.value)
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
                    .accessibilityLabel("Blood oxygen trend with baseline band")
                }

                if tonight < 95 || deviationPP < -1.5 {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(RTColor.caution)
                            .frame(width: 26, height: 26)
                            .background(RTColor.caution.opacity(0.14))
                            .clipShape(Circle())
                            .accessibilityHidden(true)

                        Text(tonight < 95
                             ? "SpO₂ under 95% can warrant attention if it persists. Check fit and altitude before worrying."
                             : "Tonight’s SpO₂ is below your personal baseline. Watch how you feel and recheck tomorrow.")
                            .font(.caption)
                            .foregroundStyle(RTColor.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer(minLength: 0)
                    }
                    .padding(12)
                    .background(RTColor.caution.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: AppleTheme.cornerRadiusMedium, style: .continuous))
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(SurfaceID.bloodOxygenCard)
        .accessibilityLabel("Blood Oxygen")
    }

    private var yDomain: ClosedRange<Double> {
        let values = chartPoints.map(\.value) + [bandLow, bandHigh, base]
        let lo = max(85, (values.min() ?? 95) - 1)
        let hi = min(100, (values.max() ?? 98) + 1)
        return lo...max(hi, lo + 1)
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
                Text(String(format: "%.0f", value))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
                    .monospacedDigit()
                Text("%")
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
        .accessibilityLabel("\(label) \(Int(value.rounded())) percent")
    }
}
