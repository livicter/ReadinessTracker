import SwiftUI
import Charts

/// Full daily detail view — tapped from History row or any daily summary.
/// Shows every metric for that day with full charts and analysis.
struct DayDetailView: View {
    let data: DailyHealthData
    let history: [DailyHealthData]
    
    @Environment(\.dismiss) private var dismiss
    
    private var previousDays: [DailyHealthData] {
        history.filter { $0.date < data.date }.sorted { $0.date < $1.date }
    }
    
    private var sevenDayWindow: [DailyHealthData] {
        let calendar = Calendar.current
        guard let weekAgo = calendar.date(byAdding: .day, value: -6, to: data.date) else { return [] }
        return history.filter { $0.date >= weekAgo && $0.date <= data.date }.sorted { $0.date < $1.date }
    }
    
    private var readinessScore: Int {
        ReadinessCalculator.calculateBreakdown(from: data, history: history).totalScore
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: RTLayout.sectionSpacing) {
                // Date header
                dateHeader
                    .slideIn(delay: 0)
                
                // Readiness score hero
                readinessHero
                    .slideIn(delay: 0.05)
                
                // Sleep deep-dive section
                sleepDeepDive
                    .slideIn(delay: 0.1)
                
                // All metrics grid
                allMetricsGrid
                    .slideIn(delay: 0.15)
                
                // 7-day context charts
                sevenDayContext
                    .slideIn(delay: 0.2)
                
                // Sleep stage analysis
                sleepStageAnalysis
                    .slideIn(delay: 0.25)
                
                // Recovery context
                recoveryContext
                    .slideIn(delay: 0.3)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(AppBackground())
        .navigationTitle(data.date.formatted(date: .abbreviated, time: .omitted))
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(RTColor.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
    
    // MARK: - Date Header
    private var dateHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(data.date, style: .date)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(RTColor.primaryText)
                
                Text(data.date, style: .time)
                    .font(.subheadline)
                    .foregroundStyle(RTColor.secondaryText)
            }
            
            Spacer()
            
            // Day of week badge
            Text(data.date.formatted(.dateTime.weekday(.wide)))
                .font(.headline.weight(.semibold))
                .foregroundStyle(RTColor.optimal)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(RTColor.optimal.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
    
    // MARK: - Readiness Hero
    private var readinessHero: some View {
        NativeCard {
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .stroke(RTColor.surfaceHighlight, lineWidth: 16)
                    
                    AnimatedRing(
                        progress: Double(readinessScore) / 100,
                        color: ScoreZone(score: readinessScore).color,
                        lineWidth: 16,
                        size: 160
                    )
                    
                    VStack(spacing: 4) {
                        Text("\(readinessScore)")
                            .font(.system(size: 52, weight: .bold, design: .rounded))
                            .foregroundStyle(RTColor.primaryText)
                        
                        Text(ScoreZone(score: readinessScore).label)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(ScoreZone(score: readinessScore).color)
                    }
                }
                .frame(width: 160, height: 160)
                
                Text(ReadinessCalculator.recommendation(for: readinessScore))
                    .font(.subheadline)
                    .foregroundStyle(RTColor.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - Sleep Deep Dive
    private var sleepDeepDive: some View {
        VStack(spacing: AppleTheme.cardPadding) {
            SectionHeader(title: "Sleep Analysis")

            if data.sleepHours > 0 {
            // Sleep hours hero
            NativeCard {
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Total Sleep")
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(RTColor.primaryText)
                            
                            HStack(alignment: .lastTextBaseline, spacing: 4) {
                                Text(String(format: "%.1f", data.sleepHours))
                                    .font(.system(size: 40, weight: .bold, design: .rounded))
                                    .foregroundStyle(RTColor.sleep)
                                Text("hours")
                                    .font(.subheadline)
                                    .foregroundStyle(RTColor.secondaryText)
                            }
                        }
                        
                        Spacer()
                        
                        // Sleep quality badge
                        let quality = sleepQualityLabel
                        VStack(spacing: 4) {
                            Text(quality.label)
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(quality.color)
                            Text(quality.subtitle)
                                .font(.caption)
                                .foregroundStyle(RTColor.secondaryText)
                        }
                        .padding(12)
                        .background(quality.color.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    
                    // Efficiency bar
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Sleep Efficiency")
                                .font(.caption)
                                .foregroundStyle(RTColor.secondaryText)
                            Spacer()
                            Text("\(Int(data.sleepEfficiency * 100))%")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(data.sleepEfficiency >= 0.85 ? RTColor.optimal : RTColor.caution)
                        }
                        
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .fill(RTColor.surfaceHighlight)
                                    .frame(height: 10)
                                
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .fill(data.sleepEfficiency >= 0.85 ? RTColor.optimal : RTColor.caution)
                                    .frame(width: geo.size.width * CGFloat(data.sleepEfficiency), height: 10)
                            }
                        }
                        .frame(height: 10)
                    }
                    
                // Sleep stages mini bar
                    SleepStageBar(stages: [
                        ("Deep", data.deepSleepPercent, RTColor.sleep),
                        ("REM", data.remSleepPercent, Color.cyan),
                        ("Light", data.lightSleepPercent, Color.blue.opacity(0.5)),
                        ("Awake", data.awakePercent, RTColor.tertiaryText)
                    ])
                    
                    HStack(spacing: 16) {
                        StageLabel(label: "Deep", percent: data.deepSleepPercent, optimal: "15-20%", isOptimal: SleepData.optimalDeep.contains(data.deepSleepPercent))
                        StageLabel(label: "REM", percent: data.remSleepPercent, optimal: "20-25%", isOptimal: SleepData.optimalRem.contains(data.remSleepPercent))
                        StageLabel(label: "Efficiency", percent: data.sleepEfficiency, optimal: ">85%", isOptimal: data.sleepEfficiency >= 0.85)
                    }
                    
                    // Link to full sleep analysis
                    NavigationLink(value: SleepDestination(data: data, history: history)) {
                        AppListRow(
                            icon: "moon.fill",
                            color: RTColor.sleep,
                            label: "Full Sleep Analysis",
                            value: ""
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            } else {
                NativeCard {
                    VStack(spacing: 12) {
                        Image(systemName: "bed.double.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(RTColor.surfaceHighlight)

                        Text("No Sleep Data")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(RTColor.primaryText)

                        Text("No sleep was recorded for this day")
                            .font(.subheadline)
                            .foregroundStyle(RTColor.secondaryText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                }
            }
        }
    }
    
    private var sleepQualityLabel: (label: String, subtitle: String, color: Color) {
        let hours = data.sleepHours
        switch hours {
        case ..<5: return ("Poor", "Not enough", RTColor.warning)
        case 5..<6.5: return ("Fair", "Could be better", RTColor.caution)
        case 6.5..<8: return ("Good", "Optimal range", RTColor.optimal)
        case 8..<10: return ("Great", "Well rested", RTColor.optimal)
        default: return ("Excess", "Might be too much", RTColor.caution)
        }
    }
    
    // MARK: - All Metrics Grid
    private var allMetricsGrid: some View {
        VStack(spacing: AppleTheme.cardPadding) {
            SectionHeader(title: "All Metrics")
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                DetailMetricItem(
                    icon: "bed.double.fill",
                    label: "Sleep",
                    value: String(format: "%.1f", data.sleepHours),
                    unit: "h",
                    color: RTColor.sleep
                )
                DetailMetricItem(
                    icon: "waveform.path.ecg",
                    label: "HRV",
                    value: "\(Int(data.hrv))",
                    unit: "ms",
                    color: RTColor.hrv
                )
                DetailMetricItem(
                    icon: "heart.fill",
                    label: "Resting HR",
                    value: "\(Int(data.restingHeartRate))",
                    unit: "bpm",
                    color: RTColor.strain
                )
                DetailMetricItem(
                    icon: "flame.fill",
                    label: "Active Cals",
                    value: "\(Int(data.activeCalories))",
                    unit: "cal",
                    color: RTColor.caution
                )
                DetailMetricItem(
                    icon: "figure.walk",
                    label: "Steps",
                    value: "\(data.steps)",
                    unit: "",
                    color: RTColor.good
                )
                DetailMetricItem(
                    icon: "dumbbell.fill",
                    label: "Workout",
                    value: "\(data.workoutMinutes)",
                    unit: "min",
                    color: RTColor.recovery
                )
                
                if let respRate = data.respiratoryRate {
                    DetailMetricItem(
                        icon: "lungs.fill",
                        label: "Resp. Rate",
                        value: String(format: "%.1f", respRate),
                        unit: "bpm",
                        color: RTColor.secondaryText
                    )
                }
                
                if let skinTemp = data.skinTemperature {
                    DetailMetricItem(
                        icon: "thermometer",
                        label: "Skin Temp",
                        value: String(format: "%.2f", skinTemp),
                        unit: "°C",
                        color: RTColor.secondaryText
                    )
                }
                
                if let spO2 = data.bloodOxygen {
                    DetailMetricItem(
                        icon: "o.circle.fill",
                        label: "SpO2",
                        value: String(format: "%.1f", spO2),
                        unit: "%",
                        color: RTColor.optimal
                    )
                }
            }
        }
    }
    
    // MARK: - 7-Day Context Charts
    private var sevenDayContext: some View {
        VStack(spacing: AppleTheme.cardPadding) {
            SectionHeader(title: "7-Day Context")
            
            if sevenDayWindow.count >= 2 {
                // Sleep trend
                NativeCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Sleep Trend")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(RTColor.primaryText)
                        
                        Chart(sevenDayWindow) { day in
                            BarMark(
                                x: .value("Date", day.date, unit: .day),
                                y: .value("Hours", day.sleepHours)
                            )
                            .foregroundStyle(day.id == data.id ? RTColor.sleep : RTColor.sleep.opacity(0.4))
                            .cornerRadius(4, style: .continuous)
                            
                            RuleMark(y: .value("Goal", 7.5))
                                .foregroundStyle(RTColor.primaryText.opacity(0.2))
                                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        }
                        .frame(height: 140)
                        .chartYAxis {
                            AxisMarks { _ in
                                AxisGridLine().foregroundStyle(RTColor.divider)
                                AxisValueLabel().foregroundStyle(RTColor.secondaryText)
                            }
                        }
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day)) { _ in
                                AxisValueLabel(format: .dateTime.weekday(.narrow))
                                    .foregroundStyle(RTColor.secondaryText)
                            }
                        }
                    }
                }
                
                // HRV trend
                NativeCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("HRV Trend")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(RTColor.primaryText)
                        
                        Chart(sevenDayWindow) { day in
                            LineMark(
                                x: .value("Date", day.date, unit: .day),
                                y: .value("HRV", day.hrv)
                            )
                            .foregroundStyle(RTColor.hrv)
                            .interpolationMethod(.catmullRom)
                            .lineStyle(StrokeStyle(lineWidth: 2.5))
                            
                            AreaMark(
                                x: .value("Date", day.date, unit: .day),
                                y: .value("HRV", day.hrv)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [RTColor.hrv.opacity(0.2), RTColor.hrv.opacity(0.0)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .interpolationMethod(.catmullRom)
                            
                            PointMark(
                                x: .value("Date", day.date, unit: .day),
                                y: .value("HRV", day.hrv)
                            )
                            .foregroundStyle(day.id == data.id ? RTColor.hrv : RTColor.hrv.opacity(0.4))
                            .symbolSize(day.id == data.id ? 80 : 40)
                        }
                        .frame(height: 140)
                        .chartYAxis {
                            AxisMarks { _ in
                                AxisGridLine().foregroundStyle(RTColor.divider)
                                AxisValueLabel().foregroundStyle(RTColor.secondaryText)
                            }
                        }
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day)) { _ in
                                AxisValueLabel(format: .dateTime.weekday(.narrow))
                                    .foregroundStyle(RTColor.secondaryText)
                            }
                        }
                    }
                }
                
                // RHR trend
                NativeCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Resting HR Trend")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(RTColor.primaryText)
                        
                        Chart(sevenDayWindow) { day in
                            LineMark(
                                x: .value("Date", day.date, unit: .day),
                                y: .value("RHR", day.restingHeartRate)
                            )
                            .foregroundStyle(RTColor.strain)
                            .interpolationMethod(.catmullRom)
                            .lineStyle(StrokeStyle(lineWidth: 2.5))
                            
                            PointMark(
                                x: .value("Date", day.date, unit: .day),
                                y: .value("RHR", day.restingHeartRate)
                            )
                            .foregroundStyle(day.id == data.id ? RTColor.strain : RTColor.strain.opacity(0.4))
                            .symbolSize(day.id == data.id ? 80 : 40)
                        }
                        .frame(height: 140)
                        .chartYAxis {
                            AxisMarks { _ in
                                AxisGridLine().foregroundStyle(RTColor.divider)
                                AxisValueLabel().foregroundStyle(RTColor.secondaryText)
                            }
                        }
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day)) { _ in
                                AxisValueLabel(format: .dateTime.weekday(.narrow))
                                    .foregroundStyle(RTColor.secondaryText)
                            }
                        }
                    }
                }
            } else {
                Text("Need more historical data for context")
                    .font(.subheadline)
                    .foregroundStyle(RTColor.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            }
        }
    }
    
    // MARK: - Sleep Stage Analysis
    private var sleepStageAnalysis: some View {
        VStack(spacing: AppleTheme.cardPadding) {
            if data.sleepHours > 0 {
                SectionHeader(title: "Sleep Stage Analysis")

                // Use the new Whoop-style SleepStageBreakdown
                SleepStageBreakdown(
                    sleepHours: data.sleepHours,
                    deepPercent: data.deepSleepPercent,
                    remPercent: data.remSleepPercent,
                    awakePercent: data.awakePercent,
                    efficiency: data.sleepEfficiency
                )

                // Sleep disturbance tracker — real bed/wake times, no synthetic awake period
                SleepDisturbanceTracker(
                    awakePeriods: SleepCycleDetector.awakePeriods(from: data.sleepStages),
                    totalSleepHours: data.sleepHours,
                    sleepStart: data.sleepStartTime,
                    sleepEnd: data.sleepEndTime
                )
            }
        }
    }
    
    private func stageDetailRow(
        icon: String,
        label: String,
        percent: Double,
        hours: Double,
        optimalRange: String,
        isOptimal: Bool,
        color: Color,
        description: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(color)
                    .frame(width: 40, height: 40)
                    .background(color.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(RTColor.primaryText)
                    
                    Text("\(Int(percent * 100))% · \(String(format: "%.1f", hours))h · Optimal: \(optimalRange)")
                        .font(.subheadline)
                        .foregroundStyle(RTColor.secondaryText)
                }
                
                Spacer()
                
                Image(systemName: isOptimal ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(isOptimal ? RTColor.optimal : RTColor.caution)
            }
            
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(RTColor.surfaceHighlight)
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(percent), height: 8)
                }
            }
            .frame(height: 8)
            
            Text(description)
                .font(.caption)
                .foregroundStyle(RTColor.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    // MARK: - Recovery Context
    private var recoveryContext: some View {
        VStack(spacing: AppleTheme.cardPadding) {
            SectionHeader(title: "Recovery Context")
            
            NativeCard {
                VStack(alignment: .leading, spacing: 16) {
                    if let prevDay = previousDays.last {
                        HStack(spacing: 12) {
                            Image(systemName: "arrow.left.arrow.right")
                                .font(.title3)
                                .foregroundStyle(RTColor.secondaryText)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("vs Previous Day")
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(RTColor.primaryText)
                                
                                let hrvChange = data.hrv - prevDay.hrv
                                let sleepChange = data.sleepHours - prevDay.sleepHours
                                let rhrChange = data.restingHeartRate - prevDay.restingHeartRate
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    changeRow(label: "HRV", change: hrvChange, unit: "ms", higherIsBetter: true)
                                    changeRow(label: "Sleep", change: sleepChange, unit: "h", higherIsBetter: true)
                                    changeRow(label: "Resting HR", change: rhrChange, unit: "bpm", higherIsBetter: false)
                                }
                            }
                        }
                    } else {
                        Text("No previous day data for comparison")
                            .font(.subheadline)
                            .foregroundStyle(RTColor.secondaryText)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 20)
                    }
                }
            }
        }
    }
    
    private func changeRow(label: String, change: Double, unit: String, higherIsBetter: Bool) -> some View {
        let isGood = (change > 0 && higherIsBetter) || (change < 0 && !higherIsBetter)
        let sign = change >= 0 ? "+" : ""
        
        return HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(RTColor.secondaryText)
            
            Spacer()
            
            Text("\(sign)\(String(format: "%.1f", change)) \(unit)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(isGood ? RTColor.optimal : RTColor.warning)
            
            Image(systemName: isGood ? "arrow.up" : "arrow.down")
                .font(.caption2)
                .foregroundStyle(isGood ? RTColor.optimal : RTColor.warning)
        }
    }
}

// MARK: - Detail Metric Item
struct DetailMetricItem: View {
    let icon: String
    let label: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        NativeCard {
            VStack(spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(color)
                    Text(label)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(RTColor.secondaryText)
                }

                HStack(alignment: .lastTextBaseline, spacing: 3) {
                    Text(value)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(RTColor.primaryText)

                    if !unit.isEmpty {
                        Text(unit)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(RTColor.secondaryText)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}
