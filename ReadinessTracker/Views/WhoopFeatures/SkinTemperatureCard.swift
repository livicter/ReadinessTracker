import SwiftUI
import Charts

/// Whoop-style skin temperature variation tracking
struct SkinTemperatureCard: View {
    let currentTemp: Double      // Current skin temp in Celsius
    let baselineTemp: Double     // Personal baseline
    let history: [(date: Date, value: Double)]
    
    private var deviation: Double {
        guard baselineTemp > 0 else { return 0 }
        return currentTemp - baselineTemp
    }
    
    private var status: (label: String, color: Color, icon: String) {
        let absDev = abs(deviation)
        if absDev < 0.3 { return ("Normal", RTColor.optimal, "checkmark.circle.fill") }
        if absDev < 0.8 { return (deviation > 0 ? "Elevated" : "Low", RTColor.caution, "exclamationmark.circle.fill") }
        return (deviation > 0 ? "Significantly Elevated" : "Significantly Low", RTColor.warning, "exclamationmark.triangle.fill")
    }
    
    var body: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Skin Temperature")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(RTColor.primaryText)
                        
                        HStack(spacing: 4) {
                            Text("\(String(format: "%.2f", currentTemp))°C")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(RTColor.primaryText)
                            
                            Text("· \(status.label)")
                                .font(.subheadline)
                                .foregroundStyle(status.color)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: status.icon)
                        .font(.title2)
                        .foregroundStyle(status.color)
                }
                
                // Deviation bar
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Deviation from baseline")
                            .font(.caption)
                            .foregroundStyle(RTColor.secondaryText)
                        
                        Spacer()
                        
                        let sign = deviation >= 0 ? "+" : ""
                        Text("\(sign)\(String(format: "%.2f", deviation))°C")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(status.color)
                    }
                    
                    // Visual deviation bar
                    GeometryReader { geo in
                        let center = geo.size.width / 2
                        let maxOffset = min(center - 20, abs(deviation) * 200)
                        
                        ZStack {
                            // Center line
                            Rectangle()
                                .fill(RTColor.surfaceHighlight)
                                .frame(width: geo.size.width, height: 8)
                                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                            
                            // Deviation indicator
                            Circle()
                                .fill(status.color)
                                .frame(width: 12, height: 12)
                                .position(
                                    x: deviation >= 0 ? center + maxOffset : center - maxOffset,
                                    y: 4
                                )
                                .shadow(color: status.color.opacity(0.4), radius: 4)
                        }
                    }
                    .frame(height: 8)
                }
                
                // Trend chart
                if history.count >= 2 {
                    Chart(history, id: \.date) { point in
                        LineMark(
                            x: .value("Date", point.date, unit: .day),
                            y: .value("Temp", point.value)
                        )
                        .foregroundStyle(RTColor.secondaryText)
                        .lineStyle(StrokeStyle(lineWidth: 1.5))
                        .interpolationMethod(.catmullRom)
                        
                        AreaMark(
                            x: .value("Date", point.date, unit: .day),
                            y: .value("Temp", point.value)
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
                        RuleMark(y: .value("Baseline", baselineTemp))
                            .foregroundStyle(RTColor.primaryText.opacity(0.2))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        
                        // Current point
                        if Calendar.current.isDateInToday(point.date) {
                            PointMark(
                                x: .value("Date", point.date, unit: .day),
                                y: .value("Temp", point.value)
                            )
                            .foregroundStyle(status.color)
                            .symbolSize(60)
                        }
                    }
                    .frame(height: 100)
                    .chartYAxis {
                        AxisMarks { _ in
                            AxisGridLine().foregroundStyle(RTColor.divider)
                            AxisValueLabel()
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
                }
                
                // Contextual insight
                if abs(deviation) > 0.5 {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(RTColor.caution)
                        
                        Text(deviation > 0
                             ? "Elevated skin temperature can indicate your body is fighting something or recovering from intense strain."
                             : "Lower skin temperature may indicate better recovery or cooler environmental conditions.")
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