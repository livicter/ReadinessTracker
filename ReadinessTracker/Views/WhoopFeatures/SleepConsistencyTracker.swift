import SwiftUI
import Charts

/// Tracks sleep consistency: bedtime, waketime, and sleep window regularity
/// Whoop-style with 7-day trend
struct SleepConsistencyTracker: View {
    let history: [(date: Date, sleepStart: Date?, sleepEnd: Date?, sleepHours: Double)]
    
    private var bedtimeConsistency: Double {
        guard history.count >= 3 else { return 0 }
        let bedtimes = history.compactMap { $0.sleepStart }
        guard bedtimes.count >= 3 else { return 0 }
        return consistencyScore(for: bedtimes)
    }

    private var wakeTimeConsistency: Double {
        guard history.count >= 3 else { return 0 }
        let wakeTimes = history.compactMap { $0.sleepEnd }
        guard wakeTimes.count >= 3 else { return 0 }
        return consistencyScore(for: wakeTimes)
    }

    /// Std-dev-based consistency score that handles midnight wrap-around:
    /// minutes-from-midnight are normalized into a circular range around an
    /// anchor, so 23:30 and 00:30 are treated as 60 minutes apart, not 1380.
    private func consistencyScore(for times: [Date]) -> Double {
        let minutes = times.map { Calendar.current.component(.hour, from: $0) * 60 + Calendar.current.component(.minute, from: $0) }

        // Wrap each sample into [anchor - 720, anchor + 720) so times near midnight stay close
        let anchor = minutes[0]
        let wrapped = minutes.map { anchor + (($0 - anchor + 2160) % 1440) - 720 }

        let mean = Double(wrapped.reduce(0, +)) / Double(wrapped.count)
        let variance = wrapped.map { pow(Double($0) - mean, 2) }.reduce(0, +) / Double(wrapped.count)
        let stdDev = sqrt(variance)

        // Lower std dev = higher consistency (max 120 min std dev = 0%, 0 min = 100%)
        return max(0, min(100, 100 - (stdDev / 120) * 100))
    }
    
    var body: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sleep Consistency")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(RTColor.primaryText)
                        
                        Text("Bedtime & wake time regularity")
                            .font(.subheadline)
                            .foregroundStyle(RTColor.secondaryText)
                    }
                    
                    Spacer()
                    
                    // Overall consistency score
                    let overall = (bedtimeConsistency + wakeTimeConsistency) / 2
                    ConsistencyBadge(score: overall)
                }
                
                // Consistency metrics
                HStack(spacing: 16) {
                    ConsistencyMetric(
                        label: "Bedtime",
                        score: bedtimeConsistency,
                        icon: "moon.fill",
                        color: Color(hex: "5E5CE6")
                    )
                    
                    ConsistencyMetric(
                        label: "Wake Time",
                        score: wakeTimeConsistency,
                        icon: "sun.max.fill",
                        color: Color(hex: "FF9500")
                    )
                }
                
                // 7-day bedtime trend chart
                if history.count >= 2 {
                    Text("Bedtime Trend")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RTColor.secondaryText)
                        .textCase(.uppercase)
                    
                    bedtimeChart
                }
            }
        }
        .accessibilityIdentifier(SurfaceID.sleepConsistency)
    }
    
    private var bedtimeChart: some View {
        let bedtimeData = history.compactMap { item -> (date: Date, minutes: Double)? in
            guard let start = item.sleepStart else { return nil }
            let mins = Double(Calendar.current.component(.hour, from: start) * 60 + Calendar.current.component(.minute, from: start))
            return (item.date, mins)
        }
        
        return Chart(bedtimeData, id: \.date) { point in
            PointMark(
                x: .value("Date", point.date, unit: .day),
                y: .value("Minutes", point.minutes)
            )
            .foregroundStyle(Color(hex: "5E5CE6"))
            .symbolSize(40)
            
            LineMark(
                x: .value("Date", point.date, unit: .day),
                y: .value("Minutes", point.minutes)
            )
            .foregroundStyle(Color(hex: "5E5CE6").opacity(0.5))
            .lineStyle(StrokeStyle(lineWidth: 1.5))
            .interpolationMethod(.catmullRom)
        }
        .frame(height: 100)
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine().foregroundStyle(RTColor.divider)
                AxisValueLabel {
                    if let mins = value.as(Double.self) {
                        let h = Int(mins) / 60
                        let m = Int(mins) % 60
                        Text(String(format: "%02d:%02d", h, m))
                            .font(.system(size: 9))
                            .foregroundStyle(RTColor.secondaryText)
                    }
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
}

private struct ConsistencyBadge: View {
    let score: Double
    
    var color: Color {
        switch score {
        case 80...100: return RTColor.optimal
        case 60..<80: return RTColor.good
        case 40..<60: return RTColor.caution
        default: return RTColor.warning
        }
    }
    
    var label: String {
        switch score {
        case 80...100: return "Excellent"
        case 60..<80: return "Good"
        case 40..<60: return "Fair"
        default: return "Poor"
        }
    }
    
    var body: some View {
        VStack(spacing: 2) {
            Text("\(Int(score))")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(RTColor.secondaryText)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(color.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: AppleTheme.cornerRadiusMedium, style: .continuous))
    }
}

private struct ConsistencyMetric: View {
    let label: String
    let score: Double
    let icon: String
    let color: Color
    
    var body: some View {
        NativeCard {
            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 12))
                        .foregroundStyle(color)
                    Text(label)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(RTColor.secondaryText)
                }

                // Mini progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(RTColor.surfaceHighlight)
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(color)
                            .frame(width: geo.size.width * CGFloat(score / 100), height: 6)
                    }
                }
                .frame(height: 6)

                Text("\(Int(score))%")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RTColor.primaryText)
            }
            .frame(maxWidth: .infinity)
        }
    }
}