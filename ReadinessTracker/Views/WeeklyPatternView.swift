import SwiftUI
import Charts

/// Day-of-week heatmap showing user's personal patterns.
/// Apple-native styling with clean bars and deviation coloring.
struct WeeklyPatternView: View {
    let history: [(date: Date, value: Double)]
    let metric: MetricType
    
    private var weeklyData: [(day: String, avg: Double, deviation: Double, color: Color)] {
        let pattern = TrendAnalysisEngine.weeklyPattern(values: history)
        let allValues = history.map { $0.value }
        let overallAvg = TrendAnalysisEngine.mean(values: allValues)
        let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        
        return (0...6).map { dayIndex in
            let avg = pattern[dayIndex] ?? overallAvg
            let dev = overallAvg > 0 ? (avg - overallAvg) / overallAvg : 0
            let color: Color
            if abs(dev) < 0.05 {
                color = RTColor.secondaryText
            } else if metric.higherIsBetter {
                color = dev > 0 ? RTColor.optimal : RTColor.warning
            } else {
                color = dev < 0 ? RTColor.optimal : RTColor.warning
            }
            return (dayNames[dayIndex], avg, dev, color)
        }
    }
    
    private var maxValue: Double {
        weeklyData.map { $0.avg }.max() ?? 1
    }
    
    var body: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 16) {
                NativeSectionHeader(title: "Weekly Pattern", action: nil)
                
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(weeklyData, id: \.day) { data in
                        VStack(spacing: 6) {
                            Text(formattedValue(data.avg))
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundStyle(data.color)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(data.color.opacity(0.3))
                                .frame(width: 32, height: barHeight(for: data.avg))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                                        .stroke(data.color.opacity(0.5), lineWidth: 1)
                                )
                            
                            Text(data.day)
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(RTColor.secondaryText)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                
                HStack(spacing: 4) {
                    Text("Personal Average: \(formattedValue(TrendAnalysisEngine.mean(values: history.map { $0.value })))")
                        .font(.caption)
                        .foregroundStyle(RTColor.secondaryText)
                    Spacer()
                }
            }
        }
        .background(AppBackground())
    }

    private func barHeight(for value: Double) -> CGFloat {
        let maxH: CGFloat = 80
        guard maxValue > 0 else { return 10 }
        return max(10, CGFloat(value / maxValue) * maxH)
    }
    
    private func formattedValue(_ value: Double) -> String {
        switch metric {
        case .sleep:
            return String(format: "%.1f", value)
        case .hrv, .restingHR, .activeCalories, .bloodOxygen:
            return "\(Int(value))"
        }
    }
}
