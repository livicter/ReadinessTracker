import SwiftUI
import Charts

/// WHOOP-style nocturnal HRV (RMSSD): Tonight vs Baseline dual callout,
/// delta, baseline band on the trend chart, and a compact 7-night sparkline.
struct SleepHRVCard: View {
    let currentHRV: Double           // Current HRV value (ms RMSSD)
    let hrvHistory: [(date: Date, value: Double)]
    let baselineHRV: Double          // Personal baseline
    let sleepQuality: Double         // 0-1 sleep quality score

    private var hRVDeviation: Double {
        guard baselineHRV > 0 else { return 0 }
        return ((currentHRV - baselineHRV) / baselineHRV) * 100
    }

    private var msDelta: Double { currentHRV - baselineHRV }

    private var recoveryStatus: (label: String, color: Color) {
        let dev = hRVDeviation
        if dev > 15 { return ("Excellent Recovery", RTColor.optimal) }
        if dev > 5 { return ("Good Recovery", RTColor.good) }
        if dev > -10 { return ("Average", RTColor.secondaryText) }
        if dev > -20 { return ("Below Average", RTColor.caution) }
        return ("Poor Recovery", RTColor.warning)
    }

    /// Last 7 nights (oldest → newest) for sparkline glance.
    private var sparklineValues: [Double] {
        let sorted = hrvHistory.sorted { $0.date < $1.date }
        return Array(sorted.suffix(7).map(\.value))
    }

    /// ±10% personal band around baseline (WHOOP-like “in range” zone).
    private var bandLow: Double { baselineHRV * 0.90 }
    private var bandHigh: Double { baselineHRV * 1.10 }

    private var chartPoints: [(date: Date, value: Double)] {
        hrvHistory.sorted { $0.date < $1.date }
    }

    var body: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 14) {
                // Header
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sleep HRV")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(RTColor.primaryText)

                        Text("RMSSD · \(recoveryStatus.label)")
                            .font(.subheadline)
                            .foregroundStyle(recoveryStatus.color)
                    }

                    Spacer()

                    let sign = hRVDeviation >= 0 ? "+" : ""
                    Text("\(sign)\(Int(hRVDeviation.rounded()))%")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(recoveryStatus.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(recoveryStatus.color.opacity(0.12))
                        .clipShape(Capsule())
                        .accessibilityLabel("\(sign)\(Int(hRVDeviation.rounded())) percent versus baseline")
                }

                // WHOOP-like Tonight | Baseline dual metric
                HStack(spacing: 12) {
                    dualColumn(
                        label: "Tonight",
                        ms: currentHRV,
                        color: recoveryStatus.color,
                        caption: deltaCaption
                    )

                    Rectangle()
                        .fill(RTColor.divider)
                        .frame(width: 1)
                        .padding(.vertical, 4)

                    dualColumn(
                        label: "Baseline",
                        ms: baselineHRV,
                        color: RTColor.secondaryText,
                        caption: "personal average"
                    )
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier(SurfaceID.sleepHRVBaselineCallout)

                // Compact 7-night sparkline
                if sparklineValues.count >= 2 {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("7-Night HRV")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(RTColor.secondaryText)
                            Spacer()
                            Text(deltaCaption)
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(msDelta >= 0 ? RTColor.optimal : RTColor.warning)
                                .monospacedDigit()
                        }
                        AnimatedSparkline(data: sparklineValues, color: RTColor.hrv)
                            .frame(height: 28)
                            .accessibilityIdentifier(SurfaceID.sleepHRVSpark)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Trend chart with baseline band
                if chartPoints.count >= 2 {
                    Chart {
                        // Baseline band (in-range zone)
                        ForEach(chartPoints, id: \.date) { point in
                            AreaMark(
                                x: .value("Date", point.date, unit: .day),
                                yStart: .value("BandLow", bandLow),
                                yEnd: .value("BandHigh", bandHigh)
                            )
                            .foregroundStyle(RTColor.hrv.opacity(0.10))
                            .interpolationMethod(.linear)
                        }

                        RuleMark(y: .value("Baseline", baselineHRV))
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
                                y: .value("HRV", point.value)
                            )
                            .foregroundStyle(RTColor.hrv)
                            .lineStyle(StrokeStyle(lineWidth: 2))
                            .interpolationMethod(.catmullRom)

                            AreaMark(
                                x: .value("Date", point.date, unit: .day),
                                yStart: .value("Floor", min(bandLow, chartPoints.map(\.value).min() ?? 0) * 0.92),
                                yEnd: .value("HRV", point.value)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [RTColor.hrv.opacity(0.14), RTColor.hrv.opacity(0)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .interpolationMethod(.catmullRom)

                            if Calendar.current.isDateInToday(point.date) {
                                PointMark(
                                    x: .value("Date", point.date, unit: .day),
                                    y: .value("HRV", point.value)
                                )
                                .foregroundStyle(recoveryStatus.color)
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
                    .accessibilityLabel("Sleep HRV trend with baseline band")
                }

                // Sleep Quality chip (compact one-liner; trend is now the dual + spark)
                HStack(spacing: 8) {
                    AppIconTile(
                        systemName: "bed.double.fill",
                        color: sleepQuality > 0.8 ? RTColor.optimal : (sleepQuality > 0.6 ? RTColor.caution : RTColor.warning),
                        size: 24
                    )
                    Text("Sleep Quality")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(RTColor.primaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .layoutPriority(1)
                    Spacer(minLength: 4)
                    Text("\(Int(sleepQuality * 100))%")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RTColor.secondaryText)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: AppleTheme.cornerRadiusMedium, style: .continuous)
                        .fill(RTColor.surfaceHighlight)
                )

                if abs(hRVDeviation) > 10 {
                    HStack(spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(RTColor.caution)

                        Text(hRVInsight)
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
        .accessibilityIdentifier(SurfaceID.sleepHRVCard)
        .accessibilityLabel("Sleep HRV")
    }

    private var deltaCaption: String {
        let sign = msDelta >= 0 ? "+" : ""
        return "\(sign)\(Int(msDelta.rounded())) ms vs baseline"
    }

    private var yDomain: ClosedRange<Double> {
        let values = chartPoints.map(\.value) + [bandLow, bandHigh, baselineHRV]
        let lo = (values.min() ?? 0) * 0.92
        let hi = (values.max() ?? 100) * 1.08
        return lo...max(hi, lo + 1)
    }

    private var hRVInsight: String {
        if hRVDeviation > 15 {
            return "Your HRV is significantly above baseline, indicating excellent recovery. Good day for high-intensity training."
        } else if hRVDeviation > 5 {
            return "HRV is above baseline. You're recovering well and can handle moderate to high strain."
        } else if hRVDeviation > -10 {
            return "HRV is near your baseline. Maintain your current routine."
        } else if hRVDeviation > -20 {
            return "HRV is below baseline. Consider reducing strain today and prioritizing recovery."
        } else {
            return "HRV is significantly suppressed. Your body needs rest. Avoid intense training."
        }
    }

    private func dualColumn(
        label: String,
        ms: Double,
        color: Color,
        caption: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(RTColor.secondaryText)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(Int(ms.rounded()))")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
                    .monospacedDigit()
                Text("ms")
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
        .accessibilityLabel("\(label) \(Int(ms.rounded())) milliseconds")
    }
}
