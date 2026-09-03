import SwiftUI
import Charts

/// 7-day rolling sleep quality trend with composite score
/// Whoop-style sleep performance over time
struct SleepQualityTrend: View {
    let history: [(date: Date, sleepScore: Int, sleepHours: Double, efficiency: Double)]
    
    private var averageScore: Double {
        guard !history.isEmpty else { return 0 }
        return Double(history.map { $0.sleepScore }.reduce(0, +)) / Double(history.count)
    }
    
    private var trendDirection: TrendDirection {
        guard history.count >= 3 else { return .flat }
        let recent = Array(history.suffix(3)).map { $0.sleepScore }.reduce(0, +) / 3
        let older = Array(history.prefix(3)).map { $0.sleepScore }.reduce(0, +) / 3
        let diff = Double(recent - older)
        if abs(diff) < 5 { return .flat }
        return diff > 0 ? .up : .down
    }
    
    var body: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sleep Quality Trend")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(RTColor.primaryText)
                        
                        HStack(spacing: 4) {
                            Text("Avg: \(Int(averageScore))")
                                .font(.subheadline)
                                .foregroundStyle(RTColor.secondaryText)
                            
                            CompactTrendIndicator(direction: trendDirection, percentChange: nil)
                        }
                    }
                    
                    Spacer()
                    
                    // 7-day avg badge
                    Text("7D")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(RTColor.primaryText)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
                
                // Score chart
                if history.count >= 2 {
                    Chart(history, id: \.date) { point in
                        // Score zone bands
                        RectangleMark(
                            xStart: .value("Date", point.date),
                            xEnd: .value("Date", Calendar.current.date(byAdding: .day, value: 1, to: point.date) ?? point.date),
                            yStart: .value("Score", 80),
                            yEnd: .value("Score", 100)
                        )
                        .foregroundStyle(RTColor.optimal.opacity(0.05))
                        
                        RectangleMark(
                            xStart: .value("Date", point.date),
                            xEnd: .value("Date", Calendar.current.date(byAdding: .day, value: 1, to: point.date) ?? point.date),
                            yStart: .value("Score", 60),
                            yEnd: .value("Score", 80)
                        )
                        .foregroundStyle(RTColor.caution.opacity(0.05))
                        
                        // Score bars
                        BarMark(
                            x: .value("Date", point.date, unit: .day),
                            y: .value("Score", point.sleepScore)
                        )
                        .foregroundStyle(scoreColor(point.sleepScore))
                        .cornerRadius(4, style: .continuous)
                        
                        // Average line
                        RuleMark(y: .value("Average", averageScore))
                            .foregroundStyle(.white.opacity(0.3))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    }
                    .frame(height: 140)
                    .chartYScale(domain: 0...100)
                    .chartYAxis {
                        AxisMarks { _ in
                            AxisGridLine().foregroundStyle(.white.opacity(0.05))
                            AxisValueLabel {
                                Text("pts")
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
                
                // Daily breakdown
                let last7 = Array(history.suffix(7))
                if last7.count >= 2 {
                    HStack(spacing: 8) {
                        ForEach(last7, id: \.date) { day in
                            VStack(spacing: 4) {
                                let dayLabel = Calendar.current.shortWeekdaySymbols[Calendar.current.component(.weekday, from: day.date) - 1]
                                Text(String(dayLabel.prefix(1)))
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(RTColor.secondaryText)
                                
                                ZStack {
                                    Circle()
                                        .stroke(scoreColor(day.sleepScore).opacity(0.3), lineWidth: 3)
                                        .frame(width: 28, height: 28)
                                    
                                    Circle()
                                        .trim(from: 0, to: Double(day.sleepScore) / 100)
                                        .stroke(scoreColor(day.sleepScore), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                                        .rotationEffect(.degrees(-90))
                                        .frame(width: 28, height: 28)
                                    
                                    Text("\(day.sleepScore)")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundStyle(RTColor.primaryText)
                                }
                                
                                Text("\(String(format: "%.1f", day.sleepHours))h")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundStyle(RTColor.secondaryText)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
        }
    }
    
    private func scoreColor(_ score: Int) -> Color {
        switch score {
        case 80...100: return RTColor.optimal
        case 60..<80: return RTColor.good
        case 40..<60: return RTColor.caution
        default: return RTColor.warning
        }
    }
}
