import SwiftUI
import Charts

/// Full sleep analysis screen with detailed sleep stages, cycles, and timing.
struct SleepAnalysisView: View {
    let data: DailyHealthData
    let history: [DailyHealthData]
    
    @Environment(\.dismiss) private var dismiss
    
    private var sleepScore: Int {
        data.sleepData.score()
    }
    
    private var sleepNeed: Double {
        BaselineManager.sleepBaseline(from: history) * 1.05
    }
    
    private var lightSleepHours: Double {
        data.sleepHours * data.lightSleepPercent
    }
    
    private var deepSleepHours: Double {
        data.sleepHours * data.deepSleepPercent
    }
    
    private var remSleepHours: Double {
        data.sleepHours * data.remSleepPercent
    }
    
    private var awakeHours: Double {
        // Awake percent applies to time in bed, not time asleep.
        timeInBed * data.awakePercent
    }
    
    private var timeInBed: Double {
        data.sleepHours / max(data.sleepEfficiency, 0.01)
    }
    
    private var estimatedCycles: Int {
        Int(data.sleepHours / 1.5)
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: AppleTheme.sectionSpacing) {
                // Header with score
                sleepHeader
                
                // Sleep timeline visualization
                sleepTimeline
                
                // Detailed stage breakdown
                stageBreakdown
                
                // Sleep cycles estimate
                sleepCyclesSection
                
                // Sleep timing analysis
                timingAnalysis
                
                // Sleep quality metrics
                qualityMetrics
                
                // 7-day stage trend
                stageTrendChart
                
                // Sleep debt
                sleepDebtSection
            }
            .padding(.horizontal, AppleTheme.horizontalMargin)
            .padding(.vertical, 12)
        }
        .background(AppBackground())
        .navigationTitle("Sleep Analysis")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(RTColor.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
    
    // MARK: - Sleep Header
    private var sleepHeader: some View {
        NativeCard {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(data.date, style: .date)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                    
                    HStack(spacing: 12) {
                        Label("\(String(format: "%.1f", data.sleepHours))h", systemImage: "bed.double.fill")
                        Label("\(Int(data.sleepEfficiency * 100))%", systemImage: "bolt.fill")
                        if data.wakeEpisodes > 0 {
                            Label("\(data.wakeEpisodes) wakes", systemImage: "exclamationmark.triangle.fill")
                        }
                    }
                    .font(.caption.weight(.medium))
                    .foregroundStyle(RTColor.secondaryText)
                }
                
                Spacer()
                
                // Sleep score ring
                ZStack {
                    Circle()
                        .stroke(RTColor.surfaceHighlight, lineWidth: 8)
                    
                    Circle()
                        .trim(from: 0, to: Double(sleepScore) / 100)
                        .stroke(scoreColor(sleepScore), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 0) {
                        Text("\(sleepScore)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Score")
                            .font(.caption2)
                            .foregroundStyle(RTColor.secondaryText)
                    }
                }
                .frame(width: 72, height: 72)
            }
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Sleep Timeline
    private var sleepTimeline: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Sleep Timeline")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                
                // Horizontal bar showing sleep stages over time
                GeometryReader { geo in
                    let width = geo.size.width
                    let totalMinutes = timeInBed * 60
                    
                    VStack(spacing: 4) {
                        // Timeline bar
                        HStack(spacing: 1) {
                            // Awake (onset is already included in awakePercent)
                            timelineSegment(
                                width: width * CGFloat((awakeHours * 60) / max(totalMinutes, 1)),
                                color: RTColor.warning,
                                label: "Awake"
                            )
                            
                            // Light sleep
                            timelineSegment(
                                width: width * CGFloat((lightSleepHours * 60) / max(totalMinutes, 1)),
                                color: Color.blue.opacity(0.5),
                                label: "Light"
                            )
                            
                            // Deep sleep
                            timelineSegment(
                                width: width * CGFloat((deepSleepHours * 60) / max(totalMinutes, 1)),
                                color: RTColor.sleep,
                                label: "Deep"
                            )
                            
                            // REM
                            timelineSegment(
                                width: width * CGFloat((remSleepHours * 60) / max(totalMinutes, 1)),
                                color: Color.cyan,
                                label: "REM"
                            )
                        }
                        .frame(height: 28)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        
                        // Time markers
                        HStack {
                            if let start = data.sleepStartTime {
                                Text(start, style: .time)
                                    .font(.caption2)
                                    .foregroundStyle(RTColor.tertiaryText)
                            } else {
                                Text("Bedtime")
                                    .font(.caption2)
                                    .foregroundStyle(RTColor.tertiaryText)
                            }
                            
                            Spacer()
                            
                            Text("\(String(format: "%.1f", timeInBed))h in bed")
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(RTColor.secondaryText)
                            
                            Spacer()
                            
                            if let end = data.sleepEndTime {
                                Text(end, style: .time)
                                    .font(.caption2)
                                    .foregroundStyle(RTColor.tertiaryText)
                            } else {
                                Text("Wake")
                                    .font(.caption2)
                                    .foregroundStyle(RTColor.tertiaryText)
                            }
                        }
                    }
                }
                .frame(height: 50)
                
                // Legend
                HStack(spacing: 16) {
                    legendItem(color: RTColor.sleep, label: "Deep", value: "\(String(format: "%.1f", deepSleepHours))h")
                    legendItem(color: Color.cyan, label: "REM", value: "\(String(format: "%.1f", remSleepHours))h")
                    legendItem(color: Color.blue.opacity(0.5), label: "Light", value: "\(String(format: "%.1f", lightSleepHours))h")
                    legendItem(color: RTColor.warning, label: "Awake", value: "\(String(format: "%.1f", awakeHours))h")
                }
            }
        }
    }
    
    private func timelineSegment(width: CGFloat, color: Color, label: String) -> some View {
        Rectangle()
            .fill(color)
            .frame(width: max(width, 4))
            .overlay(
                Group {
                    if width > 30 {
                        Text(label)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
            )
    }
    
    private func legendItem(color: Color, label: String, value: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: 0) {
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(RTColor.secondaryText)
                Text(value)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
            }
        }
    }
    
    // MARK: - Stage Breakdown
    private var stageBreakdown: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Sleep Stages")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                
                VStack(spacing: 14) {
                    stageBar(
                        label: "Deep Sleep",
                        hours: deepSleepHours,
                        percent: data.deepSleepPercent,
                        totalHours: data.sleepHours,
                        color: RTColor.sleep,
                        optimalRange: "15-20%",
                        isOptimal: SleepData.optimalDeep.contains(data.deepSleepPercent)
                    )
                    
                    stageBar(
                        label: "REM Sleep",
                        hours: remSleepHours,
                        percent: data.remSleepPercent,
                        totalHours: data.sleepHours,
                        color: Color.cyan,
                        optimalRange: "20-25%",
                        isOptimal: SleepData.optimalRem.contains(data.remSleepPercent)
                    )
                    
                    stageBar(
                        label: "Light Sleep",
                        hours: lightSleepHours,
                        percent: data.lightSleepPercent,
                        totalHours: data.sleepHours,
                        color: Color.blue.opacity(0.5),
                        optimalRange: "45-55%",
                        isOptimal: (0.45...0.55).contains(data.lightSleepPercent)
                    )
                    
                    stageBar(
                        label: "Awake",
                        hours: awakeHours,
                        percent: data.awakePercent,
                        totalHours: data.sleepHours,
                        color: RTColor.warning,
                        optimalRange: "<5%",
                        isOptimal: data.awakePercent < 0.05
                    )
                }
            }
        }
    }
    
    private func stageBar(label: String, hours: Double, percent: Double, totalHours: Double, color: Color, optimalRange: String, isOptimal: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text("\(String(format: "%.1f", hours))h")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(color)
                    Text("(\(Int(percent * 100))%)")
                        .font(.caption)
                        .foregroundStyle(RTColor.secondaryText)
                }
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(RTColor.surfaceHighlight)
                        .frame(height: 10)
                    
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(percent), height: 10)
                }
            }
            .frame(height: 10)
            
            HStack {
                Text("Optimal: \(optimalRange)")
                    .font(.caption2)
                    .foregroundStyle(isOptimal ? RTColor.optimal : RTColor.warning)
                
                Spacer()
                
                Image(systemName: isOptimal ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .font(.caption2)
                    .foregroundStyle(isOptimal ? RTColor.optimal : RTColor.warning)
            }
        }
    }
    
    // MARK: - Sleep Cycles
    private var sleepCyclesSection: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Sleep Cycles")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Text("~\(estimatedCycles) cycles")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(RTColor.secondaryText)
                }
                
                Text("Each cycle lasts ~90 min: Light → Deep → REM. You completed approximately \(estimatedCycles) full cycles.")
                    .font(.caption)
                    .foregroundStyle(RTColor.secondaryText)
                    .lineLimit(2)
                
                // Cycle visualization
                HStack(spacing: 4) {
                    ForEach(0..<min(estimatedCycles, 6), id: \.self) { i in
                        VStack(spacing: 2) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(RTColor.surfaceHighlight)
                                    .frame(width: 36, height: 48)
                                
                                VStack(spacing: 1) {
                                    Rectangle()
                                        .fill(Color.blue.opacity(0.5))
                                        .frame(width: 32, height: 12)
                                    Rectangle()
                                        .fill(RTColor.sleep)
                                        .frame(width: 32, height: 10)
                                    Rectangle()
                                        .fill(Color.cyan)
                                        .frame(width: 32, height: 14)
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 3))
                            }
                            
                            Text("\(i + 1)")
                                .font(.caption2)
                                .foregroundStyle(RTColor.tertiaryText)
                        }
                    }
                    
                    if estimatedCycles > 6 {
                        Text("+\(estimatedCycles - 6) more")
                            .font(.caption)
                            .foregroundStyle(RTColor.secondaryText)
                            .padding(.leading, 8)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
    
    // MARK: - Timing Analysis
    private var timingAnalysis: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Sleep Timing")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    timingCard(
                        label: "Sleep Onset",
                        value: "\(Int(data.sleepOnsetMinutes)) min",
                        icon: "moon.fill",
                        color: RTColor.sleep,
                        note: data.sleepOnsetMinutes < 15 ? "Fast" : data.sleepOnsetMinutes < 30 ? "Normal" : "Slow"
                    )
                    
                    timingCard(
                        label: "Time in Bed",
                        value: "\(String(format: "%.1f", timeInBed))h",
                        icon: "bed.double.fill",
                        color: Color.blue,
                        note: "vs \(String(format: "%.1f", data.sleepHours))h asleep"
                    )
                    
                    timingCard(
                        label: "Wake Episodes",
                        value: "\(data.wakeEpisodes)",
                        icon: "eye.fill",
                        color: data.wakeEpisodes <= 2 ? RTColor.optimal : RTColor.warning,
                        note: data.wakeEpisodes <= 2 ? "Good" : "Disrupted"
                    )
                    
                    timingCard(
                        label: "Sleep Efficiency",
                        value: "\(Int(data.sleepEfficiency * 100))%",
                        icon: "bolt.fill",
                        color: data.sleepEfficiency >= 0.85 ? RTColor.optimal : RTColor.warning,
                        note: data.sleepEfficiency >= 0.90 ? "Excellent" : data.sleepEfficiency >= 0.85 ? "Good" : "Fair"
                    )
                }
            }
        }
    }
    
    private func timingCard(label: String, value: String, icon: String, color: Color, note: String) -> some View {
        NativeCard {
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundStyle(color)
                    Spacer()
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(value)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                    Text(label)
                        .font(.caption2)
                        .foregroundStyle(RTColor.secondaryText)
                    Text(note)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(color)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
    
    // MARK: - Quality Metrics
    private var qualityMetrics: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Sleep Quality Factors")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                
                VStack(spacing: 12) {
                    qualityRow(
                        label: "Duration",
                        score: durationScore(),
                        detail: "\(String(format: "%.1f", data.sleepHours))h / need \(String(format: "%.1f", sleepNeed))h"
                    )
                    
                    qualityRow(
                        label: "Efficiency",
                        score: Int(data.sleepEfficiency * 100),
                        detail: "\(Int((1 - data.sleepEfficiency) * 100))% awake time"
                    )
                    
                    qualityRow(
                        label: "Deep Sleep",
                        score: Int(min(100, data.deepSleepPercent / 0.20 * 100)),
                        detail: "\(Int(data.deepSleepPercent * 100))% · \(String(format: "%.1f", deepSleepHours))h"
                    )
                    
                    qualityRow(
                        label: "REM Sleep",
                        score: Int(min(100, data.remSleepPercent / 0.25 * 100)),
                        detail: "\(Int(data.remSleepPercent * 100))% · \(String(format: "%.1f", remSleepHours))h"
                    )
                    
                    qualityRow(
                        label: "Continuity",
                        score: max(0, 100 - data.wakeEpisodes * 15),
                        detail: "\(data.wakeEpisodes) wake episodes"
                    )
                }
            }
        }
    }
    
    private func qualityRow(label: String, score: Int, detail: String) -> some View {
        HStack(spacing: 12) {
            // Score ring
            ZStack {
                Circle()
                    .stroke(RTColor.surfaceHighlight, lineWidth: 3)
                
                Circle()
                    .trim(from: 0, to: Double(score) / 100)
                    .stroke(scoreColor(score), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 32, height: 32)
            .overlay(
                Text("\(score)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
            )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(RTColor.secondaryText)
            }
            
            Spacer()
            
            Image(systemName: score >= 80 ? "checkmark.circle.fill" : score >= 60 ? "minus.circle.fill" : "xmark.circle.fill")
                .font(.title3)
                .foregroundStyle(scoreColor(score))
        }
    }
    
    // MARK: - Stage Trend Chart
    private var stageTrendChart: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("7-Day Stage Trends")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                
                if history.count >= 2 {
                    Chart(history.suffix(7)) { day in
                        BarMark(
                            x: .value("Date", day.date, unit: .day),
                            y: .value("Hours", day.sleepHours * day.deepSleepPercent)
                        )
                        .foregroundStyle(RTColor.sleep)
                        .position(by: .value("Stage", "Deep"))
                        
                        BarMark(
                            x: .value("Date", day.date, unit: .day),
                            y: .value("Hours", day.sleepHours * day.remSleepPercent)
                        )
                        .foregroundStyle(Color.cyan)
                        .position(by: .value("Stage", "REM"))
                        
                        BarMark(
                            x: .value("Date", day.date, unit: .day),
                            y: .value("Hours", day.sleepHours * day.lightSleepPercent)
                        )
                        .foregroundStyle(Color.blue.opacity(0.5))
                        .position(by: .value("Stage", "Light"))
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                    .frame(height: 160)
                } else {
                    Text("Need more data for trends")
                        .font(.caption)
                        .foregroundStyle(RTColor.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 40)
                }
                
                HStack(spacing: 16) {
                    legendItem(color: RTColor.sleep, label: "Deep", value: "")
                    legendItem(color: Color.cyan, label: "REM", value: "")
                    legendItem(color: Color.blue.opacity(0.5), label: "Light", value: "")
                }
            }
        }
    }
    
    // MARK: - Sleep Debt
    private var sleepDebtSection: some View {
        let debt = sleepNeed - data.sleepHours
        
        return NativeCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Sleep Debt")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    if debt > 0 {
                        Text("-\(String(format: "%.1f", debt))h")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(RTColor.warning)
                    } else {
                        Text("+\(String(format: "%.1f", abs(debt)))h")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(RTColor.optimal)
                    }
                }
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(RTColor.surfaceHighlight)
                            .frame(height: 20)
                        
                        let ratio = min(data.sleepHours / max(sleepNeed * 1.3, 0.1), 1.0)
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(debt > 0 ? RTColor.warning : RTColor.optimal)
                            .frame(width: geo.size.width * CGFloat(ratio), height: 20)
                        
                        // Need marker
                        Circle()
                            .fill(.white)
                            .frame(width: 10, height: 10)
                            .position(
                                x: geo.size.width * CGFloat(sleepNeed / max(sleepNeed * 1.3, 0.1)),
                                y: 10
                            )
                    }
                }
                .frame(height: 20)
                
                Text(debt > 0
                     ? "You slept \(String(format: "%.1f", debt))h less than needed. Consider an earlier bedtime tonight."
                     : "You met your sleep need. Great recovery!"
                )
                .font(.caption)
                .foregroundStyle(RTColor.secondaryText)
            }
        }
    }
    
    // MARK: - Helpers
    private func scoreColor(_ score: Int) -> Color {
        switch score {
        case 80...100: return RTColor.optimal
        case 60..<80: return RTColor.good
        case 40..<60: return RTColor.caution
        default: return RTColor.warning
        }
    }
    
    private func durationScore() -> Int {
        if SleepData.optimalHours.contains(data.sleepHours) { return 100 }
        if data.sleepHours < 4.0 { return 20 }
        if data.sleepHours < 6.0 { return 50 }
        if data.sleepHours < 7.0 { return 75 }
        if data.sleepHours > 10.0 { return 70 }
        if data.sleepHours > 9.0 { return 90 }
        return 85
    }
}
