import SwiftUI
import Charts

/// Tracks sleep disturbances: awake periods, restlessness, and sleep interruptions
/// Whoop-style with timeline visualization
struct SleepDisturbanceTracker: View {
    let awakePeriods: [(start: Date, end: Date)]
    let totalSleepHours: Double
    let sleepStart: Date?
    let sleepEnd: Date?
    
    private var totalAwakeMinutes: Double {
        awakePeriods.reduce(0) { $0 + $1.end.timeIntervalSince($1.start) / 60 }
    }
    
    private var disturbanceCount: Int {
        awakePeriods.count
    }
    
    private var sleepEfficiency: Double {
        guard let start = sleepStart, let end = sleepEnd else { return 0 }
        let totalMinutes = end.timeIntervalSince(start) / 60
        guard totalMinutes > 0 else { return 0 }
        let sleepMinutes = totalMinutes - totalAwakeMinutes
        return (sleepMinutes / totalMinutes) * 100
    }
    
    private var efficiencyStatus: (label: String, color: Color) {
        switch sleepEfficiency {
        case 90...100: return ("Excellent", RTColor.optimal)
        case 85..<90: return ("Good", RTColor.good)
        case 75..<85: return ("Fair", RTColor.caution)
        default: return ("Poor", RTColor.warning)
        }
    }
    
    var body: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sleep Disturbances")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(RTColor.primaryText)
                        
                        HStack(spacing: 4) {
                            Text("\(disturbanceCount) interruptions")
                                .font(.subheadline)
                                .foregroundStyle(RTColor.secondaryText)
                            
                            Text("· \(String(format: "%.0f", totalAwakeMinutes))min awake")
                                .font(.subheadline)
                                .foregroundStyle(RTColor.caution)
                        }
                    }
                    
                    Spacer()
                    
                    // Efficiency badge
                    let status = efficiencyStatus
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(Int(sleepEfficiency))%")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(status.color)
                        Text("Efficiency")
                            .font(.caption2)
                            .foregroundStyle(RTColor.secondaryText)
                    }
                }
                
                // Sleep timeline
                if let start = sleepStart, let end = sleepEnd {
                    sleepTimeline(start: start, end: end)
                }
                
                // Disturbance list
                if !awakePeriods.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Awake Periods")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(RTColor.secondaryText)
                            .textCase(.uppercase)
                        
                        ForEach(awakePeriods.indices, id: \.self) { i in
                            let period = awakePeriods[i]
                            let duration = period.end.timeIntervalSince(period.start) / 60
                            
                            HStack(spacing: 10) {
                                Text("\(i + 1)")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 20, height: 20)
                                    .background(RTColor.caution.opacity(0.2))
                                    .clipShape(Circle())
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(period.start, format: .dateTime.hour().minute()) - \(period.end, format: .dateTime.hour().minute())")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(RTColor.primaryText)
                                    
                                    Text("\(String(format: "%.0f", duration)) minutes")
                                        .font(.caption)
                                        .foregroundStyle(RTColor.secondaryText)
                                }
                                
                                Spacer()
                                
                                if duration > 15 {
                                    Text("Long")
                                        .font(.caption2.weight(.medium))
                                        .foregroundStyle(RTColor.warning)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(RTColor.warning.opacity(0.12))
                                        .clipShape(Capsule())
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: AppleTheme.cornerRadiusMedium, style: .continuous)
                                    .fill(RTColor.surfaceHighlight)
                            )
                        }
                    }
                }
            }
        }
    }
    
    private func sleepTimeline(start: Date, end: Date) -> some View {
        let totalDuration = end.timeIntervalSince(start)
        guard totalDuration > 0 else { return AnyView(EmptyView()) }
        
        return AnyView(
            VStack(alignment: .leading, spacing: 8) {
                Text("Sleep Timeline")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
                    .textCase(.uppercase)
                
                GeometryReader { geo in
                    let width = geo.size.width
                    
                    ZStack(alignment: .leading) {
                        // Background track
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(RTColor.surfaceHighlight)
                            .frame(height: 24)
                        
                        // Sleep segments (green)
                        let sleepSegments = calculateSleepSegments(start: start, end: end)
                        ForEach(sleepSegments.indices, id: \.self) { i in
                            let segment = sleepSegments[i]
                            let segmentStart = segment.start.timeIntervalSince(start) / totalDuration
                            let segmentWidth = segment.end.timeIntervalSince(segment.start) / totalDuration
                            
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(RTColor.optimal.opacity(0.6))
                                .frame(
                                    width: max(4, width * CGFloat(segmentWidth)),
                                    height: 20
                                )
                                .position(
                                    x: width * CGFloat(segmentStart + segmentWidth / 2),
                                    y: 12
                                )
                        }
                        
                        // Awake periods (red)
                        ForEach(awakePeriods.indices, id: \.self) { i in
                            let period = awakePeriods[i]
                            let awakeStart = period.start.timeIntervalSince(start) / totalDuration
                            let awakeWidth = period.end.timeIntervalSince(period.start) / totalDuration
                            
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(RTColor.warning)
                                .frame(
                                    width: max(4, width * CGFloat(awakeWidth)),
                                    height: 20
                                )
                                .position(
                                    x: width * CGFloat(awakeStart + awakeWidth / 2),
                                    y: 12
                                )
                        }
                    }
                }
                .frame(height: 24)
                
                // Time labels
                HStack {
                    Text(start, format: .dateTime.hour().minute())
                        .font(.caption2)
                        .foregroundStyle(RTColor.secondaryText)
                    
                    Spacer()
                    
                    Text(end, format: .dateTime.hour().minute())
                        .font(.caption2)
                        .foregroundStyle(RTColor.secondaryText)
                }
            }
        )
    }
    
    private func calculateSleepSegments(start: Date, end: Date) -> [(start: Date, end: Date)] {
        var segments: [(start: Date, end: Date)] = []
        var currentStart = start
        
        let sortedAwake = awakePeriods.sorted { $0.start < $1.start }
        
        for period in sortedAwake {
            if period.start > currentStart {
                segments.append((currentStart, period.start))
            }
            currentStart = period.end
        }
        
        if currentStart < end {
            segments.append((currentStart, end))
        }
        
        return segments
    }
}
