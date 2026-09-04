import SwiftUI

/// Whoop-style sleep performance score comparing sleep needed vs sleep obtained
struct SleepPerformanceScore: View {
    let sleepNeeded: Double      // Hours needed (14-night average)
    let sleepObtained: Double    // Actual hours slept
    let efficiency: Double       // Sleep efficiency %
    let consistency: Double      // Sleep consistency score 0-100
    var needCaption: String = "Need is your 14-night average."
    
    private var performancePercent: Double {
        guard sleepNeeded > 0 else { return 0 }
        return min(100, (sleepObtained / sleepNeeded) * 100)
    }
    
    private var performanceColor: Color {
        switch performancePercent {
        case 85...100: return RTColor.optimal
        case 70..<85: return RTColor.good
        case 50..<70: return RTColor.caution
        default: return RTColor.warning
        }
    }
    
    private var performanceLabel: String {
        switch performancePercent {
        case 85...100: return "Optimal"
        case 70..<85: return "Good"
        case 50..<70: return "Fair"
        default: return "Poor"
        }
    }
    
    var body: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sleep Performance")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(RTColor.primaryText)
                        
                        Text("\(Int(performancePercent))% · \(performanceLabel)")
                            .font(.subheadline)
                            .foregroundStyle(performanceColor)
                    }
                    
                    Spacer()
                    
                    // Circular score
                    ZStack {
                        Circle()
                            .stroke(RTColor.surfaceHighlight, lineWidth: 6)
                        
                        Circle()
                            .trim(from: 0, to: performancePercent / 100)
                            .stroke(performanceColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        
                        Text("\(Int(performancePercent))")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(RTColor.primaryText)
                    }
                    .frame(width: 56, height: 56)
                }
                
                // Sleep needed vs obtained bar
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Sleep Needed")
                            .font(.caption)
                            .foregroundStyle(RTColor.secondaryText)
                        Text(needCaption)
                            .font(.caption2)
                            .foregroundStyle(RTColor.tertiaryText)
                        Spacer()
                        Text("\(String(format: "%.1f", sleepNeeded))h")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(RTColor.primaryText)
                    }
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            // Background
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(RTColor.surfaceHighlight)
                                .frame(height: 12)
                            
                            // Obtained bar
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(performanceColor)
                                .frame(width: min(geo.size.width, geo.size.width * (sleepObtained / max(sleepNeeded * 1.3, sleepObtained))), height: 12)
                            
                            // Needed marker
                            Circle()
                                .fill(.white)
                                .frame(width: 8, height: 8)
                                .position(x: geo.size.width * (sleepNeeded / max(sleepNeeded * 1.3, sleepObtained)), y: 6)
                        }
                    }
                    .frame(height: 12)
                    
                    HStack {
                        Text("Obtained: \(String(format: "%.1f", sleepObtained))h")
                            .font(.caption)
                            .foregroundStyle(performanceColor)
                        
                        Spacer()
                        
                        let diff = sleepObtained - sleepNeeded
                        let sign = diff >= 0 ? "+" : ""
                        Text("\(sign)\(String(format: "%.1f", diff))h")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(diff >= 0 ? RTColor.optimal : RTColor.warning)
                    }
                }
                
                // Sub-metrics grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    SleepMetricItem(label: "Efficiency", value: "\(Int(efficiency))%", icon: "bolt.fill")
                    SleepMetricItem(label: "Consistency", value: "\(Int(consistency))%", icon: "clock.arrow.circlepath")
                }
            }
        }
    }
}

private struct SleepMetricItem: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        AppListRow(icon: icon, color: RTColor.secondaryText, label: label, value: value, showChevron: false)
    }
}