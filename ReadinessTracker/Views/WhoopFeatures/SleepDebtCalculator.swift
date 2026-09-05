import SwiftUI
import Charts

/// Whoop-style sleep debt tracker showing cumulative deficit/surplus
/// over time with visual "bank account" style indicator
struct SleepDebtCalculator: View {
    let history: [(date: Date, sleepHours: Double)]
    let sleepNeed: Double // Personal sleep need in hours (e.g. 8.0)
    
    private var debtData: [(date: Date, cumulativeDebt: Double, dailyHours: Double)] {
        var cumulative: Double = 0
        var result: [(date: Date, cumulativeDebt: Double, dailyHours: Double)] = []
        
        for item in history.sorted(by: { $0.date < $1.date }) {
            let dailyDebt = item.sleepHours - sleepNeed
            cumulative += dailyDebt
            result.append((item.date, cumulative, item.sleepHours))
        }
        
        return result
    }
    
    private var currentDebt: Double {
        debtData.last?.cumulativeDebt ?? 0
    }
    
    private var debtStatus: (label: String, color: Color) {
        if currentDebt > 2 { return ("Well Rested", RTColor.optimal) }
        if currentDebt > -2 { return ("Balanced", RTColor.good) }
        if currentDebt > -5 { return ("Mild Debt", RTColor.caution) }
        return ("Sleep Debt", RTColor.warning)
    }
    
    var body: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sleep Debt")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(RTColor.primaryText)
                        
                        Text("Cumulative vs \(String(format: "%.1f", sleepNeed))h need")
                            .font(.subheadline)
                            .foregroundStyle(RTColor.secondaryText)
                    }
                    
                    Spacer()
                    
                    // Current status
                    let status = debtStatus
                    VStack(alignment: .trailing, spacing: 2) {
                        let sign = currentDebt >= 0 ? "+" : ""
                        Text("\(sign)\(String(format: "%.1f", currentDebt))h")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(status.color)
                        
                        Text(status.label)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(RTColor.secondaryText)
                    }
                }
                
                // Debt trend chart
                if debtData.count >= 2 {
                    let statusColor = debtStatus.color
                    Chart(debtData, id: \.date) { point in
                        // Zero line
                        RuleMark(y: .value("Zero", 0))
                            .foregroundStyle(RTColor.primaryText.opacity(0.2))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        
                        // Area fill (green above zero, red below)
                        AreaMark(
                            x: .value("Date", point.date, unit: .day),
                            y: .value("Debt", point.cumulativeDebt)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    point.cumulativeDebt >= 0 ? RTColor.optimal.opacity(0.2) : RTColor.warning.opacity(0.2),
                                    point.cumulativeDebt >= 0 ? RTColor.optimal.opacity(0) : RTColor.warning.opacity(0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)
                        
                        // Line
                        LineMark(
                            x: .value("Date", point.date, unit: .day),
                            y: .value("Debt", point.cumulativeDebt)
                        )
                        .foregroundStyle(point.cumulativeDebt >= 0 ? RTColor.optimal : RTColor.warning)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        .interpolationMethod(.catmullRom)
                        
                        // Current point
                        if Calendar.current.isDateInToday(point.date) {
                            PointMark(
                                x: .value("Date", point.date, unit: .day),
                                y: .value("Debt", point.cumulativeDebt)
                            )
                            .foregroundStyle(statusColor)
                            .symbolSize(80)
                        }
                    }
                    .frame(height: 140)
                    .chartYAxis {
                        AxisMarks { _ in
                            AxisGridLine().foregroundStyle(RTColor.divider)
                            AxisValueLabel {
                                Text("h")
                                    .font(.system(size: 9))
                                    .foregroundStyle(RTColor.secondaryText)
                            }
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
                
                // Daily breakdown
                let last7 = Array(debtData.suffix(7))
                if last7.count >= 2 {
                    HStack(spacing: 12) {
                        ForEach(last7.indices, id: \.self) { i in
                            let item = last7[i]
                            let prevDebt = i > 0 ? last7[i - 1].cumulativeDebt : item.cumulativeDebt
                            let dailyChange = item.cumulativeDebt - prevDebt
                            
                            VStack(spacing: 4) {
                                let dayLabel = Calendar.current.shortWeekdaySymbols[Calendar.current.component(.weekday, from: item.date) - 1]
                                Text(String(dayLabel.prefix(1)))
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(RTColor.secondaryText)
                                
                                // Mini bar
                                RoundedRectangle(cornerRadius: 2, style: .continuous)
                                    .fill(dailyChange >= 0 ? RTColor.optimal : RTColor.warning)
                                    .frame(width: 20, height: max(4, abs(dailyChange) * 15))
                                
                                Text("\(String(format: "%.1f", item.dailyHours))")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundStyle(RTColor.primaryText)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.top, 8)
                }
            }
        }
        .accessibilityIdentifier(SurfaceID.sleepDebtCard)
    }
}
