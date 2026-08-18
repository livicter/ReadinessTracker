import SwiftUI
import Charts

/// Whoop-style respiratory rate tracking with trend
struct RespiratoryRateCard: View {
    let currentRate: Double      // breaths per minute
    let history: [(date: Date, value: Double)]
    let baseline: Double
    
    private var deviation: Double {
        guard baseline > 0 else { return 0 }
        return ((currentRate - baseline) / baseline) * 100
    }
    
    private var status: (label: String, color: Color) {
        let absDev = abs(deviation)
        if absDev < 5 { return ("Normal", RTColor.optimal) }
        if absDev < 15 { return ("Slightly Elevated", RTColor.caution) }
        return ("Elevated", RTColor.warning)
    }
    
    var body: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Respiratory Rate")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white)
                        
                        HStack(spacing: 4) {
                            Text("\(String(format: "%.1f", currentRate)) bpm")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.white)
                            
                            Text("· \(status.label)")
                                .font(.subheadline)
                                .foregroundStyle(status.color)
                        }
                    }
                    
                    Spacer()
                    
                    // Trend indicator
                    VStack(alignment: .trailing, spacing: 2) {
                        let sign = deviation >= 0 ? "+" : ""
                        Text("\(sign)\(String(format: "%.1f", deviation))%")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(deviation > 0 ? RTColor.warning : RTColor.optimal)
                        
                        Text("vs baseline")
                            .font(.caption2)
                            .foregroundStyle(RTColor.secondaryText)
                    }
                }
                
                // Mini trend chart
                if history.count >= 2 {
                    Chart(history, id: \.date) { point in
                        LineMark(
                            x: .value("Date", point.date, unit: .day),
                            y: .value("Rate", point.value)
                        )
                        .foregroundStyle(RTColor.secondaryText)
                        .lineStyle(StrokeStyle(lineWidth: 1.5))
                        .interpolationMethod(.catmullRom)
                        
                        AreaMark(
                            x: .value("Date", point.date, unit: .day),
                            y: .value("Rate", point.value)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [RTColor.secondaryText.opacity(0.1), RTColor.secondaryText.opacity(0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)
                        
                        // Baseline rule
                        RuleMark(y: .value("Baseline", baseline))
                            .foregroundStyle(.white.opacity(0.2))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        
                        // Current point highlight
                        if Calendar.current.isDateInToday(point.date) {
                            PointMark(
                                x: .value("Date", point.date, unit: .day),
                                y: .value("Rate", point.value)
                            )
                            .foregroundStyle(status.color)
                            .symbolSize(60)
                        }
                    }
                    .frame(height: 100)
                    .chartYAxis {
                        AxisMarks { _ in
                            AxisGridLine().foregroundStyle(.white.opacity(0.05))
                            AxisValueLabel()
                                .foregroundStyle(RTColor.secondaryText)
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day)) { _ in
                            AxisGridLine().foregroundStyle(.white.opacity(0.05))
                            AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                                .foregroundStyle(RTColor.secondaryText)
                        }
                    }
                }
                
                // Contextual insight
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
    }
}