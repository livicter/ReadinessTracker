import SwiftUI

/// Contextual smart insights based on trend analysis.
/// Generates human-readable recommendations from statistical patterns.
struct SmartInsightsView: View {
    let metric: MetricType
    let history: [(date: Date, value: Double)]
    let currentValue: Double
    
    var insights: [Insight] {
        var results: [Insight] = []
        let values = history.map { $0.value }
        guard values.count >= 3 else { return [] }
        
        let baseline = TrendAnalysisEngine.mean(values: values)
        let stdDev = TrendAnalysisEngine.standardDeviation(values: values)
        let zScore = TrendAnalysisEngine.zScore(value: currentValue, baseline: baseline, stdDev: stdDev)
        let cv = TrendAnalysisEngine.coefficientOfVariation(values: values)
        
        // 1. Zone insight
        if let zone = metric.zone(for: currentValue) {
            let icon = zone.color == RTColor.optimal ? "checkmark.circle.fill" :
                       zone.color == RTColor.warning ? "exclamationmark.triangle.fill" : "info.circle.fill"
            results.append(Insight(
                icon: icon,
                color: zone.color,
                title: "\(metric.title) is \(zone.label.lowercased())",
                detail: zone.description
            ))
        }
        
        // 2. Deviation insight
        if abs(zScore) > 1.5 {
            let isHigh = zScore > 0
            let direction = isHigh ? "above" : "below"
            let significance = abs(zScore) > 2 ? "significantly" : "noticeably"
            let goodOrBad = (isHigh && metric.higherIsBetter) || (!isHigh && !metric.higherIsBetter) ? "good" : "concerning"
            
            results.append(Insight(
                icon: isHigh ? "arrow.up.circle.fill" : "arrow.down.circle.fill",
                color: goodOrBad == "good" ? RTColor.optimal : RTColor.warning,
                title: "\(significance.capitalized) \(direction) your average",
                detail: "Your \(metric.title.lowercased()) is \(String(format: "%.1f", abs(zScore)))σ \(direction) your personal baseline of \(Int(baseline)) \(metric.unit)"
            ))
        }
        
        // 3. Volatility insight
        if cv > 0.15 {
            let level = cv > 0.25 ? "Highly variable" : "Moderately variable"
            results.append(Insight(
                icon: "waveform",
                color: RTColor.caution,
                title: "\(level) pattern",
                detail: "Your \(metric.title.lowercased()) fluctuates by \(Int(cv * 100))% on average. Consistency may help improve recovery scores."
            ))
        } else if values.count >= 14 {
            results.append(Insight(
                icon: "checkmark.shield.fill",
                color: RTColor.optimal,
                title: "Consistent pattern",
                detail: "Your \(metric.title.lowercased()) stays within a stable range. Keep it up!"
            ))
        }
        
        // 4. Trend insight
        if values.count >= 7 {
            let (slope, r2, _) = TrendAnalysisEngine.linearRegression(values: values)
            if r2 > 0.3 {
                let normalizedSlope: Double
                switch metric {
                case .sleep: normalizedSlope = slope / 7.5 * 100
                case .hrv: normalizedSlope = slope / 50.0 * 100
                case .restingHR: normalizedSlope = slope / 60.0 * 100
                case .activeCalories: normalizedSlope = slope / 400.0 * 100
                case .bloodOxygen: normalizedSlope = slope / 5.0 * 100
                }
                
                let isImproving = (normalizedSlope > 0 && metric.higherIsBetter) || (normalizedSlope < 0 && !metric.higherIsBetter)
                let trendLabel = isImproving ? "Improving" : "Declining"
                let trendIcon = isImproving ? "chart.line.uptrend.xyaxis" : "chart.line.downtrend.xyaxis"
                let trendColor = isImproving ? RTColor.optimal : RTColor.warning
                
                results.append(Insight(
                    icon: trendIcon,
                    color: trendColor,
                    title: "\(trendLabel) trend",
                    detail: "Your \(metric.title.lowercased()) has been \(isImproving ? "improving" : "declining") by \(String(format: "%.1f", abs(normalizedSlope)))% per day over the selected period."
                ))
            }
        }
        
        // 5. Consistency streak
        if values.count >= 5 {
            var streak = 0
            for value in values.reversed() {
                let z = TrendAnalysisEngine.zScore(value: value, baseline: baseline, stdDev: stdDev)
                if abs(z) < 1.0 {
                    streak += 1
                } else {
                    break
                }
            }
            if streak >= 3 {
                results.append(Insight(
                    icon: "flame.fill",
                    color: RTColor.optimal,
                    title: "\(streak)-day stability streak",
                    detail: "Your \(metric.title.lowercased()) has stayed within normal range for \(streak) consecutive days."
                ))
            }
        }
        
        return results
    }
    
    var body: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 12) {
                NativeSectionHeader(title: "Insights", action: nil)
                    .padding(.horizontal, 4)

                if insights.isEmpty {
                    Text("Not enough data for insights")
                        .font(.subheadline)
                        .foregroundStyle(RTColor.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 20)
                } else {
                    VStack(spacing: 8) {
                        ForEach(insights) { insight in
                            InsightRow(insight: insight)
                        }
                    }
                }
            }
        }
        .background(AppBackground())
    }
}

struct Insight: Identifiable {
    let id = UUID()
    let icon: String
    let color: Color
    let title: String
    let detail: String
}

struct InsightRow: View {
    let insight: Insight
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: insight.icon)
                .font(.title3.weight(.semibold))
                .foregroundStyle(insight.color)
                .frame(width: 36, height: 36)
                .background(insight.color.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(insight.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)

                Text(insight.detail)
                    .font(.caption)
                    .foregroundStyle(RTColor.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: AppleTheme.cornerRadiusMedium, style: .continuous)
                .fill(RTColor.surfaceHighlight)
        )
    }
}
