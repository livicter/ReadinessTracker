import SwiftUI
import Charts

/// Recovery trajectory showing how a metric recovers after high-strain days.
/// Compares post-workout recovery patterns to baseline.
struct RecoveryTrajectoryView: View {
    let history: [(date: Date, value: Double)]
    let metric: MetricType
    
    /// Simple strain proxy: days with above-average active calories
    private var strainDays: [(date: Date, value: Double)] {
        // Use a simple heuristic: we don't have workout data here,
        // so we'll use days where the metric itself deviates significantly
        // as a proxy for strain/recovery pattern
        let values = history.map { $0.value }
        let baseline = TrendAnalysisEngine.mean(values: values)
        let stdDev = TrendAnalysisEngine.standardDeviation(values: values)
        
        return history.filter { point in
            let z = TrendAnalysisEngine.zScore(value: point.value, baseline: baseline, stdDev: stdDev)
            // For HRV/sleep: low values indicate strain; for RHR: high values indicate strain
            return metric.higherIsBetter ? z < -1.0 : z > 1.0
        }
    }
    
    private var recoveryPoints: [RecoveryPoint] {
        guard history.count >= 5 else { return [] }
        let values = history.map { $0.value }
        let baseline = TrendAnalysisEngine.mean(values: values)
        
        var points: [RecoveryPoint] = []
        
        // Find days after significant deviations and track recovery
        for i in 0..<(history.count - 1) {
            let current = history[i]
            let next = history[i + 1]
            
            let currentZ = TrendAnalysisEngine.zScore(
                value: current.value,
                baseline: baseline,
                stdDev: TrendAnalysisEngine.standardDeviation(values: values)
            )
            
            // Day after a significant deviation
            if abs(currentZ) > 1.0 {
                let recoveryPct = metric.higherIsBetter
                    ? (next.value - current.value) / current.value * 100
                    : (current.value - next.value) / current.value * 100
                
                points.append(RecoveryPoint(
                    day: i,
                    dayLabel: "Day \(i + 1)",
                    recoveryPercent: recoveryPct,
                    isBackToBaseline: abs(next.value - baseline) < baseline * 0.1
                ))
            }
        }
        
        return points.suffix(10) // Last 10 recovery events
    }
    
    var body: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 12) {
            NativeSectionHeader(title: "Recovery Pattern", action: nil)
                .padding(.horizontal, 4)
            
            if recoveryPoints.isEmpty {
                Text("Not enough data for recovery analysis")
                    .font(.subheadline)
                    .foregroundStyle(RTColor.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            } else {
                Chart(recoveryPoints) { point in
                    BarMark(
                        x: .value("Day", point.dayLabel),
                        y: .value("Recovery", point.recoveryPercent)
                    )
                    .foregroundStyle(point.recoveryPercent > 0 ? RTColor.optimal : RTColor.warning)
                    .cornerRadius(4, style: .continuous)
                    
                    if point.isBackToBaseline {
                        RuleMark(
                            x: .value("Day", point.dayLabel)
                        )
                        .foregroundStyle(RTColor.optimal.opacity(0.3))
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [4, 4]))
                    }
                }
                .frame(height: 160)
                .chartYAxisLabel("% Change", position: .trailing)
                .chartYAxis {
                    AxisMarks { _ in
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
                
                // Recovery stats
                let avgRecovery = recoveryPoints.map { $0.recoveryPercent }.reduce(0.0, +) / Double(recoveryPoints.count)
                let backToBaselineCount = recoveryPoints.filter { $0.isBackToBaseline }.count
                
                HStack(spacing: 16) {
                    StatMini(
                        label: "Avg Recovery",
                        value: "\(String(format: "%.1f", avgRecovery))%"
                    )
                    StatMini(
                        label: "Back to Normal",
                        value: "\(backToBaselineCount)/\(recoveryPoints.count)"
                    )
                }
            }
        }
        }
        .background(AppBackground())
    }
}

struct RecoveryPoint: Identifiable {
    let id = UUID()
    let day: Int
    let dayLabel: String
    let recoveryPercent: Double
    let isBackToBaseline: Bool
}
