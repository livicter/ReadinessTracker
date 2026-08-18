import SwiftUI
import Charts

/// Whoop-style nocturnal HRV tracking
/// Shows HRV during sleep with recovery correlation
struct SleepHRVCard: View {
    let currentHRV: Double           // Current HRV value
    let hrvHistory: [(date: Date, value: Double)]
    let baselineHRV: Double          // Personal baseline
    let sleepQuality: Double         // 0-1 sleep quality score
    
    private var hRVDeviation: Double {
        guard baselineHRV > 0 else { return 0 }
        return ((currentHRV - baselineHRV) / baselineHRV) * 100
    }
    
    private var recoveryStatus: (label: String, color: Color) {
        let dev = hRVDeviation
        if dev > 15 { return ("Excellent Recovery", RTColor.optimal) }
        if dev > 5 { return ("Good Recovery", RTColor.good) }
        if dev > -10 { return ("Average", RTColor.secondaryText) }
        if dev > -20 { return ("Below Average", RTColor.caution) }
        return ("Poor Recovery", RTColor.warning)
    }
    
    var body: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sleep HRV")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white)
                        
                        HStack(spacing: 4) {
                            Text("\(Int(currentHRV)) ms")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.white)
                            
                            let status = recoveryStatus
                            Text("· \(status.label)")
                                .font(.subheadline)
                                .foregroundStyle(status.color)
                        }
                    }
                    
                    Spacer()
                    
                    // Deviation badge
                    let sign = hRVDeviation >= 0 ? "+" : ""
                    Text("\(sign)\(Int(hRVDeviation))%")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(recoveryStatus.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(recoveryStatus.color.opacity(0.12))
                        .clipShape(Capsule())
                }
                
                // HRV trend chart
                if hrvHistory.count >= 2 {
                    Chart(hrvHistory, id: \.date) { point in
                        RuleMark(y: .value("Baseline", baselineHRV))
                            .foregroundStyle(.white.opacity(0.2))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        
                        // HRV line
                        LineMark(
                            x: .value("Date", point.date, unit: .day),
                            y: .value("HRV", point.value)
                        )
                        .foregroundStyle(RTColor.hrv)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        .interpolationMethod(.catmullRom)
                        
                        AreaMark(
                            x: .value("Date", point.date, unit: .day),
                            y: .value("HRV", point.value)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [RTColor.hrv.opacity(0.15), RTColor.hrv.opacity(0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)
                        
                        // Current point highlight
                        if Calendar.current.isDateInToday(point.date) {
                            PointMark(
                                x: .value("Date", point.date, unit: .day),
                                y: .value("HRV", point.value)
                            )
                            .foregroundStyle(recoveryStatus.color)
                            .symbolSize(80)
                        }
                    }
                    .frame(height: 120)
                    .chartYAxis {
                        AxisMarks { _ in
                            AxisGridLine().foregroundStyle(.white.opacity(0.05))
                            AxisValueLabel {
                                Text("ms")
                                    .font(.system(size: 9))
                                    .foregroundStyle(RTColor.secondaryText)
                            }
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
                
                // Recovery correlation insight
                HStack(spacing: 12) {
                    HStack(spacing: 12) {
                        AppIconTile(
                            systemName: hRVDeviation > 0 ? "arrow.up.forward" : "arrow.down.forward",
                            color: recoveryStatus.color
                        )
                        Text("HRV Trend")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white)
                        Spacer()
                        Text(hRVDeviation > 0 ? "Rising" : "Falling")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(RTColor.secondaryText)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: AppleTheme.cornerRadiusMedium, style: .continuous)
                            .fill(RTColor.surfaceHighlight)
                    )

                    HStack(spacing: 12) {
                        AppIconTile(
                            systemName: "bed.double.fill",
                            color: sleepQuality > 0.8 ? RTColor.optimal : (sleepQuality > 0.6 ? RTColor.caution : RTColor.warning)
                        )
                        Text("Sleep Quality")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white)
                        Spacer()
                        Text("\(Int(sleepQuality * 100))%")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(RTColor.secondaryText)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: AppleTheme.cornerRadiusMedium, style: .continuous)
                            .fill(RTColor.surfaceHighlight)
                    )
                }
                
                // Insight text
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
}