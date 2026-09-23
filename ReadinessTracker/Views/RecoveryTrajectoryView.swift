import SwiftUI
import Charts

/// WHOOP-style post-strain recovery trajectory.
/// Elevates unused `TrendAnalysisEngine.recoveryTrajectory`: average metric
/// on Day+1…Day+N after high-strain days, vs personal baseline.
struct RecoveryTrajectoryView: View {
    let metricHistory: [(date: Date, value: Double)]
    let strainHistory: [(date: Date, value: Double)]
    let metricLabel: String
    let unit: String
    let higherIsBetter: Bool
    let color: Color
    var recoveryWindow: Int = 5
    var strainThresholdOverride: Double? = nil

    /// MetricDetail / AdvancedMetric convenience.
    init(
        history: [(date: Date, value: Double)],
        strainHistory: [(date: Date, value: Double)],
        metric: MetricType,
        recoveryWindow: Int = 5,
        strainThresholdOverride: Double? = nil
    ) {
        self.metricHistory = history
        self.strainHistory = strainHistory
        self.metricLabel = metric.title
        self.unit = metric.unit
        self.higherIsBetter = metric.higherIsBetter
        self.color = metric.color
        self.recoveryWindow = recoveryWindow
        self.strainThresholdOverride = strainThresholdOverride
    }

    /// Recovery & Strain page: recovery score after high strain.
    init(
        metricHistory: [(date: Date, value: Double)],
        strainHistory: [(date: Date, value: Double)],
        metricLabel: String,
        unit: String,
        higherIsBetter: Bool,
        color: Color,
        recoveryWindow: Int = 5,
        strainThresholdOverride: Double? = nil
    ) {
        self.metricHistory = metricHistory
        self.strainHistory = strainHistory
        self.metricLabel = metricLabel
        self.unit = unit
        self.higherIsBetter = higherIsBetter
        self.color = color
        self.recoveryWindow = recoveryWindow
        self.strainThresholdOverride = strainThresholdOverride
    }

    private var strainThreshold: Double {
        if let override = strainThresholdOverride { return override }
        let vals = strainHistory.map(\.value)
        guard !vals.isEmpty else { return .infinity }
        return TrendAnalysisEngine.mean(values: vals)
    }

    private var eventCount: Int {
        strainHistory.filter { $0.value >= strainThreshold }.count
    }

    private var trajectory: [TrajectoryDay] {
        let raw = TrendAnalysisEngine.recoveryTrajectory(
            metricValues: metricHistory,
            strainValues: strainHistory,
            strainThreshold: strainThreshold,
            recoveryWindow: recoveryWindow
        )
        return (1...recoveryWindow).compactMap { offset in
            guard let samples = raw[offset], !samples.isEmpty else { return nil }
            let avg = TrendAnalysisEngine.mean(values: samples)
            return TrajectoryDay(
                offset: offset,
                label: "Day+\(offset)",
                average: avg,
                sampleCount: samples.count
            )
        }
    }

    private var baseline: Double {
        TrendAnalysisEngine.mean(values: metricHistory.map(\.value))
    }

    private var yDomain: ClosedRange<Double> {
        let vals = trajectory.map(\.average) + [baseline]
        guard let lo = vals.min(), let hi = vals.max(), lo < hi else {
            return (baseline * 0.85)...(baseline * 1.15)
        }
        let pad = max((hi - lo) * 0.15, abs(baseline) * 0.02 + 1)
        return (lo - pad)...(hi + pad)
    }

    private var daysToBaseline: Int? {
        guard !trajectory.isEmpty, baseline > 0 else { return nil }
        let tol = abs(baseline) * 0.05
        for day in trajectory {
            let recovered: Bool
            if higherIsBetter {
                recovered = day.average >= baseline - tol
            } else {
                recovered = day.average <= baseline + tol
            }
            if recovered { return day.offset }
        }
        return nil
    }

    var body: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    NativeSectionHeader(title: "Post-Strain Recovery", action: nil)
                    Spacer(minLength: 8)
                    Text("\(eventCount) hard days")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(RTColor.secondaryText)
                        .accessibilityIdentifier(SurfaceID.postStrainEventCount)
                }
                .padding(.horizontal, 4)

                Text("Avg \(metricLabel) after high-strain days")
                    .font(.caption)
                    .foregroundStyle(RTColor.secondaryText)
                    .padding(.horizontal, 4)

                if trajectory.count < 2 || eventCount == 0 {
                    Text("Need more high-strain days for trajectory")
                        .font(.subheadline)
                        .foregroundStyle(RTColor.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 40)
                } else {
                    Chart {
                        RuleMark(y: .value("Baseline", baseline))
                            .foregroundStyle(RTColor.tertiaryText.opacity(0.7))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                            .annotation(position: .top, alignment: .trailing) {
                                Text("Baseline")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundStyle(RTColor.tertiaryText)
                            }

                        ForEach(trajectory) { day in
                            LineMark(
                                x: .value("Day", day.label),
                                y: .value(metricLabel, day.average)
                            )
                            .foregroundStyle(color)
                            .lineStyle(StrokeStyle(lineWidth: 2.5))
                            .interpolationMethod(.catmullRom)

                            AreaMark(
                                x: .value("Day", day.label),
                                y: .value(metricLabel, day.average)
                            )
                            .foregroundStyle(color.opacity(0.12))
                            .interpolationMethod(.catmullRom)

                            PointMark(
                                x: .value("Day", day.label),
                                y: .value(metricLabel, day.average)
                            )
                            .foregroundStyle(color)
                            .symbolSize(48)
                        }
                    }
                    .frame(height: 168)
                    .chartYScale(domain: yDomain)
                    .chartYAxis {
                        AxisMarks(position: .leading) { _ in
                            AxisGridLine().foregroundStyle(RTColor.divider)
                            AxisValueLabel()
                                .foregroundStyle(RTColor.secondaryText)
                        }
                    }
                    .chartXAxis {
                        AxisMarks { _ in
                            AxisGridLine().foregroundStyle(RTColor.divider)
                            AxisValueLabel()
                                .foregroundStyle(RTColor.secondaryText)
                        }
                    }
                    .accessibilityIdentifier(SurfaceID.postStrainRecoveryChart)

                    HStack(spacing: 16) {
                        StatMini(
                            label: "Baseline",
                            value: formatted(baseline)
                        )
                        if let d = daysToBaseline {
                            StatMini(
                                label: "Back by",
                                value: "Day+\(d)"
                            )
                        } else {
                            StatMini(
                                label: "Back by",
                                value: "—"
                            )
                        }
                        if let first = trajectory.first {
                            StatMini(
                                label: "Day+1",
                                value: formatted(first.average)
                            )
                        }
                    }
                }
            }
            .accessibilityIdentifier(SurfaceID.postStrainRecoveryCard)
        }
        .background(AppBackground())
        .accessibilityIdentifier(SurfaceID.postStrainRecoveryCard)
    }

    private func formatted(_ value: Double) -> String {
        if unit.isEmpty {
            return String(format: "%.0f", value)
        }
        if unit == "ms" || unit == "bpm" || unit == "cal" {
            return String(format: "%.0f", value)
        }
        if abs(value) >= 10 {
            return String(format: "%.0f", value)
        }
        return String(format: "%.1f", value)
    }
}

private struct TrajectoryDay: Identifiable {
    var id: Int { offset }
    let offset: Int
    let label: String
    let average: Double
    let sampleCount: Int
}
