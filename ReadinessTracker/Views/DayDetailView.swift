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

    /// History through this day — WeeklyPattern / RecoveryTrajectory need ≥7 / ≥5 points.
    private var sleepSeriesThroughDay: [(date: Date, value: Double)] {
        history
            .filter { $0.date <= data.date }
            .sorted { $0.date < $1.date }
            .map { ($0.date, $0.sleepHours) }
    }

    private var strainSeriesThroughDay: [(date: Date, value: Double)] {
        history
            .filter { $0.date <= data.date }
            .sorted { $0.date < $1.date }
            .map { ($0.date, $0.activeCalories) }
    }

    /// DailyHealthData through this day — MetricCorrelationView needs full rows.
    private var historyThroughDay: [DailyHealthData] {
        history
            .filter { $0.date <= data.date }
            .sorted { $0.date < $1.date }
    }

    /// Honest #272: TrendAnalysisEngine.analyze on Sleep through day (classic/Trends outlier parity).
    private var sleepAnalyzedThroughDay: [AnalyzedDataPoint] {
        TrendAnalysisEngine.analyze(history: sleepSeriesThroughDay, metric: .sleep)
    }

    /// Honest #273: baseline ±2σ from Sleep through day (classic / Trends #258 parity).
    private var sleepBaselineStats: (baseline: Double, stdDev: Double)? {
        let vals = sleepSeriesThroughDay.map(\.value)
        guard vals.count >= 5 else { return nil }
        let stdDev = TrendAnalysisEngine.standardDeviation(values: vals)
        guard stdDev > 0 else { return nil }
        return (TrendAnalysisEngine.mean(values: vals), stdDev)
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

                // Honest #267: SmartInsightsView on Sleep series (≥3 days in window).
                if sevenDayWindow.count >= 3 {
                    SmartInsightsView(
                        metric: .sleep,
                        history: sevenDayWindow.map { ($0.date, $0.sleepHours) },
                        currentValue: data.sleepHours
                    )
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier(SurfaceID.dayDetailSmartInsights)
                    .slideIn(delay: 0.22)
                }

                // Honest #268: WeeklyPatternView on Sleep series (≥7 days through day).
                if sleepSeriesThroughDay.count >= 7 {
                    WeeklyPatternView(
                        history: sleepSeriesThroughDay,
                        metric: .sleep
                    )
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier(SurfaceID.dayDetailWeeklyPattern)
                    .slideIn(delay: 0.23)
                }

                // Honest #269: RecoveryTrajectoryView (≥5 days + activeCalories strain).
                if sleepSeriesThroughDay.count >= 5 {
                    RecoveryTrajectoryView(
                        history: sleepSeriesThroughDay,
                        strainHistory: strainSeriesThroughDay,
                        metric: .sleep
                    )
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier(SurfaceID.dayDetailRecoveryTrajectory)
                    .slideIn(delay: 0.24)
                }

                // Honest #270: MetricCorrelationView Sleep↔HRV (classic / Trends #266 parity).
                if historyThroughDay.count >= 3 {
                    MetricCorrelationView(
                        history: historyThroughDay,
                        xMetric: .sleep,
                        yMetric: .hrv
                    )
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier(SurfaceID.dayDetailMetricCorrelation)
                    .slideIn(delay: 0.245)
                }

                // Honest #271: DistributionHistogramView on Sleep (classic / Trends #255 parity).
                if sleepSeriesThroughDay.count >= 5 {
                    DistributionHistogramView(
                        history: sleepSeriesThroughDay,
                        metric: .sleep
                    )
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier(SurfaceID.dayDetailHistogram)
                    .slideIn(delay: 0.247)
                }

                // Honest #272: OutlierCallout Highlights on Sleep (classic #251 / Trends #257 parity).
                dayDetailOutlierSection
                    .slideIn(delay: 0.248)
                
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
        .toolbarColorScheme(.light, for: .navigationBar)
    }
    


    private func dayDetailBandColor(zScore: Double) -> Color {
        let absZ = abs(zScore)
        if absZ > 2 { return .red }
        if absZ > 1 { return .orange }
        return RTColor.sleep
    }

    // MARK: - Outlier Highlights (Honest #272)
    /// Elevate unused isOutlier via OutlierCallout list (up to 3) — classic / Trends parity.
    @ViewBuilder
    private var dayDetailOutlierSection: some View {
        let outliers = sleepAnalyzedThroughDay.filter(\.isOutlier)
        if !outliers.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Highlights")
                    .font(RTFont.headline)
                    .foregroundColor(RTColor.primaryText)
                    .padding(.horizontal, 4)

                VStack(spacing: 8) {
                    ForEach(outliers.prefix(3)) { point in
                        let type: OutlierCallout.OutlierType = point.zScore > 0 ? .high : .low
                        let dateStr = point.date.formatted(.dateTime.month(.abbreviated).day())
                        let sign = point.zScore > 0 ? "+" : ""
                        let deviationStr = "\(sign)\(String(format: "%.1f", point.zScore))σ"
                        OutlierCallout(
                            type: type,
                            value: "\(String(format: "%.1f", point.rawValue)) h",
                            date: dateStr,
                            deviation: deviationStr
                        )
                    }
                }
                .accessibilityIdentifier(SurfaceID.dayDetailOutlierList)
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(SurfaceID.dayDetailOutlierList)
            .accessibilityLabel("Outlier highlights")
        }
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
    
    // MARK: - Sleep Deep Dive (WHOOP night-detail clarity)
    private var sleepDeepDive: some View {
        VStack(spacing: AppleTheme.cardPadding) {
            SectionHeader(title: "Sleep Analysis")

            if data.sleepHours > 0 {
                NativeCard {
                    VStack(spacing: 16) {
                        nightHeaderMetrics
                            .accessibilityIdentifier(SurfaceID.dayDetailHeader)

                        stagePercentChips
                            .accessibilityIdentifier(SurfaceID.dayDetailStageChips)

                        if !data.sleepStages.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Sleep Timeline")
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(RTColor.primaryText)
                                HypnogramView(intervals: data.sleepStages, interactive: false)
                            }
                            .accessibilityIdentifier(SurfaceID.dayDetailHypnogram)
                        }

                        cyclesSummary
                            .accessibilityIdentifier(SurfaceID.dayDetailCycles)

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
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier(SurfaceID.dayDetail)
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

    private var nightSleepScore: Int {
        data.sleepData.score()
    }

    private var timeInBedHours: Double {
        data.sleepHours / max(data.sleepEfficiency, 0.01)
    }

    private var detectedCycles: [SleepCycle] {
        SleepCycleDetector.detectCycles(in: data.sleepStages)
    }

    private var nightHeaderMetrics: some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                Circle()
                    .stroke(RTColor.surfaceHighlight, lineWidth: 7)

                Circle()
                    .trim(from: 0, to: Double(nightSleepScore) / 100)
                    .stroke(sleepScoreColor(nightSleepScore), style: StrokeStyle(lineWidth: 7, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 0) {
                    Text("\(nightSleepScore)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(RTColor.primaryText)
                        .monospacedDigit()
                    Text("Score")
                        .font(.caption2)
                        .foregroundStyle(RTColor.secondaryText)
                }
            }
            .frame(width: 64, height: 64)
            .accessibilityLabel("Sleep score \(nightSleepScore)")

            HStack(spacing: 0) {
                nightMetricColumn(
                    label: "Asleep",
                    value: String(format: "%.1f", data.sleepHours),
                    unit: "h",
                    color: RTColor.sleep,
                    icon: "moon.fill"
                )
                nightMetricDivider
                nightMetricColumn(
                    label: "In Bed",
                    value: String(format: "%.1f", timeInBedHours),
                    unit: "h",
                    color: RTColor.primaryText,
                    icon: "bed.double.fill"
                )
                nightMetricDivider
                nightMetricColumn(
                    label: "Efficiency",
                    value: "\(Int(data.sleepEfficiency * 100))",
                    unit: "%",
                    color: data.sleepEfficiency >= 0.85 ? RTColor.optimal : RTColor.caution,
                    icon: "bolt.fill"
                )
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var nightMetricDivider: some View {
        Rectangle()
            .fill(RTColor.divider)
            .frame(width: 1, height: 36)
            .padding(.horizontal, 6)
    }

    private func nightMetricColumn(label: String, value: String, unit: String, color: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                // Honest #98: Apple circular tint well on Day Detail night metrics.
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(width: 22, height: 22)
                    .background(color.opacity(0.14))
                    .clipShape(Circle())
                    .accessibilityHidden(true)
                Text(label)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
            }
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
                    .monospacedDigit()
                Text(unit)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(RTColor.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var stagePercentChips: some View {
        let light = max(0, 1.0 - data.deepSleepPercent - data.remSleepPercent - data.awakePercent)
        let chips: [(label: String, percent: Double, hours: Double, color: Color)] = [
            ("Deep", data.deepSleepPercent, data.sleepHours * data.deepSleepPercent, SleepStage.deep.color),
            ("REM", data.remSleepPercent, data.sleepHours * data.remSleepPercent, SleepStage.rem.color),
            ("Core", light, data.sleepHours * light, SleepStage.light.color),
            ("Awake", data.awakePercent, timeInBedHours * data.awakePercent, RTColor.caution),
        ]
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(chips, id: \.label) { chip in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(chip.color)
                            .frame(width: 8, height: 8)
                        VStack(alignment: .leading, spacing: 0) {
                            Text(chip.label)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(RTColor.secondaryText)
                            Text("\(Int(chip.percent * 100))% · \(String(format: "%.1f", chip.hours))h")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(RTColor.primaryText)
                                .monospacedDigit()
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(chip.color.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .accessibilityLabel("\(chip.label) \(Int(chip.percent * 100)) percent")
                }
            }
        }
        .accessibilityLabel("Sleep stage percentages")
    }

    private var cyclesSummary: some View {
        let cycles = detectedCycles
        let avg: Double = {
            guard !cycles.isEmpty else { return 0 }
            return cycles.reduce(0) { $0 + $1.durationMinutes } / Double(cycles.count)
        }()
        return HStack(spacing: 12) {
            // Honest #87: Apple circular tint well on Day Detail Sleep Cycles header.
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(RTColor.sleep)
                .frame(width: 26, height: 26)
                .background(RTColor.sleep.opacity(0.14))
                .clipShape(Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("Sleep Cycles")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RTColor.primaryText)
                if cycles.isEmpty {
                    Text("No cycles detected yet")
                        .font(.caption)
                        .foregroundStyle(RTColor.secondaryText)
                } else {
                    Text("\(cycles.count) \(cycles.count == 1 ? "cycle" : "cycles") · avg \(Int(avg)) min")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(RTColor.secondaryText)
                        .monospacedDigit()
                }
            }
            Spacer()
            if !cycles.isEmpty {
                Text("\(cycles.count)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(RTColor.sleep)
                    .monospacedDigit()
            }
        }
        .accessibilityLabel(
            cycles.isEmpty
                ? "Sleep cycles none detected"
                : "Sleep cycles \(cycles.count), average \(Int(avg)) minutes"
        )
    }

    private func sleepScoreColor(_ score: Int) -> Color {
        switch score {
        case 80...100: return RTColor.optimal
        case 60..<80: return RTColor.good
        case 40..<60: return RTColor.caution
        default: return RTColor.warning
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
                        
                        Chart {
                            // Honest #273: ±2σ baseline bands on Sleep (classic #251 / Trends #258).
                            if let stats = sleepBaselineStats {
                                let cal = Calendar.current
                                let low = stats.baseline - 2 * stats.stdDev
                                let high = stats.baseline + 2 * stats.stdDev
                                ForEach(sevenDayWindow) { day in
                                    let endDate = cal.date(byAdding: .day, value: 1, to: day.date) ?? day.date
                                    let z = TrendAnalysisEngine.zScore(
                                        value: day.sleepHours,
                                        baseline: stats.baseline,
                                        stdDev: stats.stdDev
                                    )
                                    RectangleMark(
                                        xStart: .value("Date", day.date),
                                        xEnd: .value("Date", endDate),
                                        yStart: .value("Low", low),
                                        yEnd: .value("High", high)
                                    )
                                    .foregroundStyle(dayDetailBandColor(zScore: z).opacity(0.08))
                                }
                                RuleMark(y: .value("Baseline", stats.baseline))
                                    .foregroundStyle(RTColor.primaryText.opacity(0.25))
                                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [6, 4]))
                            }

                            ForEach(sevenDayWindow) { day in
                                BarMark(
                                    x: .value("Date", day.date, unit: .day),
                                    y: .value("Hours", day.sleepHours)
                                )
                                .foregroundStyle(day.id == data.id ? RTColor.sleep : RTColor.sleep.opacity(0.4))
                                .cornerRadius(4, style: .continuous)
                            }

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

                        // Honest #273: Baseline ±2σ legend (Trends #258 presentation parity).
                        if sleepBaselineStats != nil {
                            HStack(spacing: 6) {
                                Capsule()
                                    .stroke(RTColor.tertiaryText, style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                                    .frame(width: 18, height: 2)
                                Text("Baseline")
                                    .font(.caption2)
                                    .foregroundStyle(RTColor.secondaryText)
                                    .accessibilityIdentifier(SurfaceID.dayDetailBaselineBands)
                                Text("±2σ")
                                    .font(.caption2)
                                    .foregroundStyle(RTColor.tertiaryText)
                                Spacer(minLength: 0)
                            }
                            .accessibilityElement(children: .contain)
                            .accessibilityIdentifier(SurfaceID.dayDetailBaselineBands)
                            .accessibilityLabel("Baseline bands plus or minus two sigma")
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

                // Apple Health–style stage breakdown (bar + under-labels)
                SleepStageBreakdown(
                    sleepHours: data.sleepHours,
                    deepPercent: data.deepSleepPercent,
                    remPercent: data.remSleepPercent,
                    awakePercent: data.awakePercent,
                    efficiency: data.sleepEfficiency
                )

                // Full cycle composition when stages exist
                if !detectedCycles.isEmpty {
                    SleepCycleView(cycles: detectedCycles)
                }

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
                // Honest #79: Apple circular tint well on Day Detail stage rows.
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(width: 40, height: 40)
                    .background(color.opacity(0.14))
                    .clipShape(Circle())
                    .accessibilityHidden(true)
                
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
                            // Honest #87: Apple circular tint well on vs Previous Day header.
                            Image(systemName: "arrow.left.arrow.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(RTColor.secondaryText)
                                .frame(width: 26, height: 26)
                                .background(RTColor.secondaryText.opacity(0.14))
                                .clipShape(Circle())
                                .accessibilityHidden(true)
                            
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
                HStack(spacing: 8) {
                    // Honest #79: circular tint well on Day Detail metric chips.
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(color)
                        .frame(width: 26, height: 26)
                        .background(color.opacity(0.14))
                        .clipShape(Circle())
                        .accessibilityHidden(true)
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
