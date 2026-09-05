import SwiftUI
import Charts
import UIKit

struct DashboardView: View {
    @StateObject private var healthKit = HealthKitManager.shared
    @StateObject private var fitbit = FitbitManager.shared
    @StateObject private var dataStore = DataStore.shared
    @StateObject private var metadataStore = MetadataStore.shared
    @State private var selectedSource: DataSource = .appleWatch
    @State private var trendPeriod: TrendPeriod = .week
    @State private var quickTrendWindow: Int = 7
    @State private var isRefreshing = false
    @State private var lastSyncDate: Date?
    @State private var dismissedError: String?
    @State private var isWeeklyReportPresented = false
    @Environment(\.openURL) private var openURL

    private var latestData: DailyHealthData? {
        dataStore.latest(for: selectedSource)
    }

    private var currentError: String? {
        let message = selectedSource == .appleWatch ? healthKit.errorMessage : fitbit.errorMessage
        guard let message, message != dismissedError else { return nil }
        return message
    }

    private var isInitialLoading: Bool {
        latestData == nil && isRefreshing
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppleTheme.sectionSpacing) {
                        sourcePicker

                        if let data = latestData {
                            let history = dataStore.dataForSource(selectedSource, days: trendPeriod.rawValue)
                            let longHistory = dataStore.dataForSource(selectedSource, days: 180)
                            let metadata = metadataStore.metadataFor(date: Date(), timeOfDay: .morning)
                            let dualScores = ReadinessCalculator.calculateDualScores(from: data, history: history, metadata: metadata)

                            // Apply strain decay and cognitive lag
                            let yesterdayMetadata = metadataStore.previousEveningMetadata()
                            let strainAdjusted = ReadinessCalculator.applyStrainDecay(
                                to: dualScores.gym,
                                previousRPE: yesterdayMetadata?.workoutRPE,
                                daysSinceWorkout: 1
                            )
                            let cognitiveAdjusted = ReadinessCalculator.applyCognitiveLag(
                                to: dualScores.cognitive,
                                previousMentalFatigue: yesterdayMetadata?.mentalFatigue,
                                previousWorkloadStress: yesterdayMetadata?.workloadStress,
                                daysSince: 1
                            )

                            let finalScores = DualReadinessScores(
                                general: dualScores.general,
                                cognitive: cognitiveAdjusted,
                                gym: strainAdjusted,
                                breakdown: dualScores.breakdown
                            )

                            heroSection(scores: finalScores, data: data, history: history)
                                .slideIn(delay: 0)

                            syncStatusBar
                                .slideIn(delay: 0.05)

                            if let error = currentError {
                                errorBanner(error)
                                    .slideIn(delay: 0.08)
                            }

                            checkInSection
                                .slideIn(delay: 0.1)
                            journalButton
                                .slideIn(delay: 0.13)
                            recommendationsSection(scores: finalScores)
                                .slideIn(delay: 0.16)
                            whoopSection(data: data, history: history, scores: finalScores)
                                .slideIn(delay: 0.2)
                            bodyActivitySection(data: data)
                                .slideIn(delay: 0.22)
                            metricsSection(data: data, history: history)
                                .slideIn(delay: 0.24)
                            quickTrendsSection(history: longHistory)
                                .slideIn(delay: 0.28)
                            sleepSection(data: data)
                                .slideIn(delay: 0.32)
                            breakdownSection(breakdown: dualScores.breakdown, data: data, history: history)
                                .slideIn(delay: 0.36)
                            trendSection(history: history)
                                .slideIn(delay: 0.4)
                        } else {
                            syncStatusBar

                            if let error = currentError {
                                errorBanner(error)
                            }

                            if isInitialLoading {
                                loadingView
                            } else {
                                noDataView
                            }
                        }
                    }
                    .padding(.horizontal, AppleTheme.horizontalMargin)
                    .padding(.vertical, 12)
                }
                .refreshable {
                    await performRefresh()
                }
            }
            .navigationTitle("Readiness")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(RTColor.background, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isWeeklyReportPresented = true
                    } label: {
                        Image(systemName: "doc.text")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(RTColor.primaryText)
                    }
                }
            }
            .sheet(isPresented: $isWeeklyReportPresented) {
                NavigationStack {
                    if let report = WeeklyReportGenerator.shared.generateReport(for: selectedSource) {
                        WeeklyReportView(report: report)
                            .toolbar {
                                ToolbarItem(placement: .navigationBarTrailing) {
                                    Button("Done") { isWeeklyReportPresented = false }
                                }
                            }
                    } else {
                        Text("Need at least 3 days of data for a weekly report")
                            .foregroundStyle(RTColor.secondaryText)
                            .padding()
                            .navigationTitle("Weekly Report")
                            .toolbar {
                                ToolbarItem(placement: .navigationBarTrailing) {
                                    Button("Done") { isWeeklyReportPresented = false }
                                }
                            }
                    }
                }
            }
            .onAppear {
                Haptic.prepare()
                lastSyncDate = latestData?.date
            }
            .onChange(of: selectedSource) { _ in
                dismissedError = nil
                lastSyncDate = latestData?.date
                Task { await initialLoadIfNeeded() }
            }
            .task {
                await initialLoadIfNeeded()
            }
        }
    }

    // MARK: - Source Picker
    private var sourcePicker: some View {
        VStack(spacing: 4) {
            HStack(spacing: 8) {
                ForEach(DataSource.allCases, id: \.self) { source in
                    Button(action: {
                        Haptic.selectionChanged()
                        selectedSource = source
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: source == .appleWatch ? "heart.fill" : "figure.walk")
                                .font(.system(size: 12))
                            Text(source.rawValue)
                                .font(.subheadline.weight(.medium))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(selectedSource == source ? RTColor.surfaceHighlight : Color.clear)
                        .foregroundStyle(selectedSource == source ? RTColor.primaryText : RTColor.secondaryText)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }

                Spacer()
            }
            .padding(4)
            .background(RTColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppleTheme.cornerRadiusSmall, style: .continuous))

            // Data source indicator
            if selectedSource == .appleWatch {
                HStack(spacing: 4) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 6))
                        .foregroundStyle(healthKit.isAuthorized ? RTColor.optimal : .gray)
                    Text(Self.healthKitSourceLabel(healthKit.dataSource))
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(RTColor.secondaryText)
                }
                .padding(.horizontal, 8)
            }
        }
    }

    // MARK: - Sync Status Bar
    private var syncStatusBar: some View {
        SyncStatusView(
            lastSync: lastSyncDate,
            isSyncing: isRefreshing,
            sourceName: selectedSource == .appleWatch ? healthKit.dataSource : "Fitbit",
            onSync: {
                Haptic.press()
                Task { await performRefresh() }
            }
        )
    }

    // MARK: - Error Banner
    private func errorBanner(_ message: String) -> some View {
        NativeCard {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(RTColor.warning)

                Text(message)
                    .font(.caption)
                    .foregroundStyle(RTColor.secondaryText)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                Button {
                    Haptic.press()
                    Task { await performRefresh() }
                } label: {
                    Text("Retry")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RTColor.optimal)
                }
                .buttonStyle(.plain)
                .disabled(isRefreshing)

                Button {
                    Haptic.tap()
                    dismissedError = message
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(RTColor.tertiaryText)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Hero Section (Triple Ring)
    private func heroSection(scores: DualReadinessScores, data: DailyHealthData, history: [DailyHealthData]) -> some View {
        let zone = ScoreZone(score: scores.general)

        return NavigationLink(destination: ReadinessDetailView(
            scores: scores,
            data: data,
            history: history
        )) {
            NativeCard {
                VStack(spacing: 20) {
                    // Eyebrow + zone badge
                    HStack {
                        Text("TODAY'S READINESS")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(RTColor.secondaryText)
                            .tracking(1.5)

                        Spacer()

                        Text(zone.label.uppercased())
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(zone.color)
                            .padding(.horizontal, AppleTheme.badgeHPadding)
                            .padding(.vertical, 4)
                            .background(zone.color.opacity(AppleTheme.badgeBgOpacity))
                            .clipShape(Capsule())
                    }

                    // Triple ring
                    TripleRingHero(
                        gymScore: scores.gym,
                        workScore: scores.cognitive,
                        sleepScore: scores.breakdown.sleepScore,
                        size: 220
                    )

                    // Legend
                    RingLegend(
                        gymScore: scores.gym,
                        workScore: scores.cognitive,
                        sleepScore: scores.breakdown.sleepScore
                    )

                    // Recommendation
                    Text(scores.recommendation())
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(RTColor.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            }
            .overlay(
                HStack {
                    Spacer()
                    VStack {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(RTColor.tertiaryText)
                            .padding(12)
                        Spacer()
                    }
                }
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Readiness detail")
    }

    // MARK: - Recommendations Section
    private func recommendationsSection(scores: DualReadinessScores) -> some View {
        let recs = AIRecommendationEngine.shared.generateRecommendations(for: selectedSource)
            .prefix(2)

        return Group {
            if !recs.isEmpty {
                NativeCard {
                    VStack(alignment: .leading, spacing: AppleTheme.cardPadding) {
                        SectionHeader(title: "Recommendations")

                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(Array(recs.enumerated()), id: \.offset) { _, rec in
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: "lightbulb.fill")
                                        .font(.system(size: 14))
                                        .foregroundStyle(Color(hex: rec.priority.color))
                                        .frame(width: 32, height: 32)
                                        .background(Color(hex: rec.priority.color).opacity(0.12))
                                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(rec.title)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(RTColor.primaryText)

                                        Text(rec.description)
                                            .font(.caption)
                                            .foregroundStyle(RTColor.secondaryText)
                                            .multilineTextAlignment(.leading)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Check-in Section
    private var checkInSection: some View {
        HStack(spacing: 12) {
            NavigationLink(destination: CheckInView(initialTime: .morning, embedsNavigationStack: false)) {
                CheckInStatusCard(
                    label: "Morning",
                    icon: "sunrise.fill",
                    isDone: metadataStore.hasCheckedInToday(.morning),
                    color: RTColor.caution
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Morning check-in")

            NavigationLink(destination: CheckInView(initialTime: .evening, embedsNavigationStack: false)) {
                CheckInStatusCard(
                    label: "Evening",
                    icon: "sunset.fill",
                    isDone: metadataStore.hasCheckedInToday(.evening),
                    color: RTColor.sleep
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Evening check-in")
        }
    }

    // MARK: - Journal Button
    private var journalButton: some View {
        NavigationLink(destination: JournalView()) {
            NativeCard {
                HStack(spacing: 12) {
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(RTColor.optimal)
                        .frame(width: 36, height: 36)
                        .background(RTColor.optimal.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Journal")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(RTColor.primaryText)
                        Text("Track behaviors affecting recovery")
                            .font(.caption)
                            .foregroundStyle(RTColor.secondaryText)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(RTColor.tertiaryText)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Metrics Section
    private func metricsSection(data: DailyHealthData, history: [DailyHealthData]) -> some View {
        let hrvHistory = history.map { Double($0.hrv) }
        let rhrHistory = history.map { Double($0.restingHeartRate) }
        let sleepHistory = history.map { $0.sleepHours }

        let hrvBase = BaselineManager.hrvBaseline(from: history, matchesRMSSD: data.hrvIsRMSSD)
        let rhrBase = BaselineManager.rhrBaseline(from: history)

        return VStack(spacing: AppleTheme.cardPadding) {
            SectionHeader(title: "Metrics")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                MetricCard(
                    title: "Sleep",
                    value: String(format: "%.1f", data.sleepHours),
                    unit: "h",
                    icon: "bed.double.fill",
                    color: RTColor.sleep,
                    trend: trendFor(data.sleepHours, baseline: BaselineManager.sleepBaseline(from: history), higherIsBetter: true),
                    sparklineData: sleepHistory,
                    metricType: .sleep,
                    currentValue: data.sleepHours,
                    history: history,
                    source: selectedSource
                )

                MetricCard(
                    title: data.hrvIsRMSSD ? "RMSSD" : "HRV",
                    value: "\(Int(data.hrv))",
                    unit: "ms",
                    icon: "waveform.path.ecg",
                    color: RTColor.hrv,
                    trend: trendFor(Double(data.hrv), baseline: hrvBase, higherIsBetter: true),
                    sparklineData: hrvHistory,
                    metricType: .hrv,
                    currentValue: data.hrv,
                    history: history,
                    source: selectedSource
                )

                MetricCard(
                    title: "Resting HR",
                    value: "\(Int(data.restingHeartRate))",
                    unit: "bpm",
                    icon: "heart.fill",
                    color: RTColor.strain,
                    trend: trendFor(Double(data.restingHeartRate), baseline: rhrBase, higherIsBetter: false),
                    sparklineData: rhrHistory,
                    metricType: .restingHR,
                    currentValue: data.restingHeartRate,
                    history: history,
                    source: selectedSource
                )

                MetricCard(
                    title: "Active Cals",
                    value: "\(Int(data.activeCalories))",
                    unit: "cal",
                    icon: "flame.fill",
                    color: RTColor.caution,
                    trend: .flat,
                    sparklineData: history.map { Double($0.activeCalories) },
                    metricType: .activeCalories,
                    currentValue: data.activeCalories,
                    history: history,
                    source: selectedSource
                )
            }
        }
    }

    // MARK: - Quick Trends Section
    private func quickTrendsSection(history: [DailyHealthData]) -> some View {
        VStack(spacing: AppleTheme.cardPadding) {
            HStack {
                SectionHeader(title: "Quick Trends")
                Spacer()

                Picker("", selection: $quickTrendWindow) {
                    Text("7D").tag(7)
                    Text("30D").tag(30)
                    Text("90D").tag(90)
                }
                .pickerStyle(.segmented)
                .frame(width: 150)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    QuickTrendCard(metric: .sleep, history: history, window: quickTrendWindow)
                        .frame(width: 160)

                    QuickTrendCard(metric: .hrv, history: history, window: quickTrendWindow)
                        .frame(width: 160)

                    QuickTrendCard(metric: .restingHR, history: history, window: quickTrendWindow)
                        .frame(width: 160)

                    QuickTrendCard(metric: .activeCalories, history: history, window: quickTrendWindow)
                        .frame(width: 160)
                }
            }
        }
    }

    // MARK: - Sleep Section
    private func sleepSection(data: DailyHealthData) -> some View {
        NavigationLink(destination: SleepAnalysisView(
            data: data,
            history: dataStore.dataForSource(selectedSource, days: trendPeriod.rawValue)
        )) {
            NativeCard {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        SectionHeader(title: "Sleep Stages")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(RTColor.tertiaryText)
                    }

                    SleepStageBar(stages: [
                        ("Deep", data.deepSleepPercent, RTColor.sleep),
                        ("REM", data.remSleepPercent, RTColor.consistency),
                        ("Light", data.lightSleepPercent, RTColor.sleep.opacity(0.5)),
                        ("Awake", data.awakePercent, RTColor.tertiaryText)
                    ])

                    HStack(spacing: 16) {
                        StageLabel(label: "Deep", percent: data.deepSleepPercent, optimal: "15-20%", isOptimal: SleepData.optimalDeep.contains(data.deepSleepPercent))
                        StageLabel(label: "REM", percent: data.remSleepPercent, optimal: "20-25%", isOptimal: SleepData.optimalRem.contains(data.remSleepPercent))
                        StageLabel(label: "Efficiency", percent: data.sleepEfficiency, optimal: ">85%", isOptimal: data.sleepEfficiency >= 0.85)
                    }

                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(data.wakeEpisodes <= 2 ? RTColor.optimal : RTColor.caution)
                        Text(data.wakeEpisodes == 1 ? "1 disturbance" : "\(data.wakeEpisodes) disturbances")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(RTColor.secondaryText)
                    }
                    .accessibilityLabel("Sleep disturbances")
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - WHOOP-Style Section
    private func whoopSection(data: DailyHealthData, history: [DailyHealthData], scores: DualReadinessScores) -> some View {
        let strainValue = scores.breakdown.strainScoreValue
        let sleepNeed = BaselineManager.sleepNeed(from: history)
        let recoveryScore = RecoveryCalculator.dashboardWheelScore(from: data, history: history)

        return VStack(spacing: AppleTheme.cardPadding) {
            NavigationLink(destination: RecoveryStrainDetailView(
                data: data,
                history: history,
                scores: scores
            )) {
                VStack(spacing: AppleTheme.cardPadding) {
                    HStack {
                        SectionHeader(title: "Recovery & Strain")
                        Spacer()
                        Text(String(format: "%.1f", strainValue))
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(RTColor.caution)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(RTColor.tertiaryText)
                    }

                    NativeCard {
                        StrainRecoveryWheel(
                            strainScore: strainValue,
                            recoveryScore: recoveryScore,
                            day: "TODAY"
                        )
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Recovery and strain detail")

            SleepPerformanceScore(
                sleepNeeded: sleepNeed,
                sleepObtained: data.sleepHours,
                efficiency: data.sleepEfficiency * 100,
                consistency: calculateSleepConsistency(history: history)
            )

            if data.hrv > 0 {
                SleepHRVCard(
                    currentHRV: data.hrv,
                    hrvHistory: history.filter { $0.hrv > 0 }.map { ($0.date, $0.hrv) },
                    baselineHRV: BaselineManager.hrvBaseline(from: history, matchesRMSSD: data.hrvIsRMSSD),
                    sleepQuality: data.sleepEfficiency
                )
                .accessibilityIdentifier(SurfaceID.sleepHRVCard)
            } else {
                MissingMetricRow(title: "Sleep HRV")
                    .accessibilityIdentifier(SurfaceID.sleepHRVCard)
            }

            if history.contains(where: { $0.sleepHours > 0 }) {
                SleepDebtCalculator(
                    history: history.map { ($0.date, $0.sleepHours) },
                    sleepNeed: sleepNeed
                )
                .accessibilityIdentifier(SurfaceID.sleepDebtCard)
                SleepQualityTrend(
                    history: history.map { ($0.date, $0.sleepData.score(), $0.sleepHours, $0.sleepEfficiency) }
                )
                .accessibilityIdentifier(SurfaceID.sleepQualityTrend)
                SleepConsistencyTracker(
                    history: history.map { ($0.date, $0.sleepStartTime, $0.sleepEndTime, $0.sleepHours) }
                )
                .accessibilityIdentifier(SurfaceID.sleepConsistency)
            } else {
                MissingMetricRow(title: "Sleep Debt")
                    .accessibilityIdentifier(SurfaceID.sleepDebtCard)
                MissingMetricRow(title: "Sleep Quality Trend")
                    .accessibilityIdentifier(SurfaceID.sleepQualityTrend)
                MissingMetricRow(title: "Sleep Consistency")
                    .accessibilityIdentifier(SurfaceID.sleepConsistency)
            }

            StrainRecoveryBalanceCard(balance: scores.balance)

            HStack(spacing: 12) {
                if let respRate = data.respiratoryRate {
                    RespiratoryRateCard(
                        currentRate: respRate,
                        history: history.compactMap { d in
                            d.respiratoryRate.map { (d.date, $0) }
                        },
                        baseline: history.compactMap { $0.respiratoryRate }.reduce(0, +) / Double(max(1, history.compactMap { $0.respiratoryRate }.count))
                    )
                } else {
                    MissingMetricRow(title: "Respiratory Rate")
                }

                if let skinTemp = data.skinTemperature {
                    let tempHistory = history.compactMap { d in
                        d.skinTemperature.map { (date: d.date, value: $0) }
                    }
                    let baseline = tempHistory.map { $0.value }.reduce(0, +) / Double(max(1, tempHistory.count))
                    SkinTemperatureCard(
                        currentTemp: skinTemp,
                        baselineTemp: baseline > 0 ? baseline : skinTemp,
                        history: tempHistory
                    )
                } else {
                    MissingMetricRow(title: "Skin Temperature")
                }
            }
        }
        .accessibilityIdentifier(SurfaceID.whoopSection)
    }

    private func calculateSleepConsistency(history: [DailyHealthData]) -> Double {
        guard history.count >= 3 else { return 50 }
        let sleepHours = history.map { $0.sleepHours }
        let mean = sleepHours.reduce(0, +) / Double(sleepHours.count)
        let variance = sleepHours.map { pow($0 - mean, 2) }.reduce(0, +) / Double(sleepHours.count)
        let stdDev = sqrt(variance)
        // Lower stdDev = higher consistency (100 - normalized stdDev * factor)
        return max(0, min(100, 100 - stdDev * 30))
    }

    // MARK: - Breakdown Section
    private func breakdownSection(breakdown: ReadinessBreakdown, data: DailyHealthData, history: [DailyHealthData]) -> some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: "Breakdown")

                VStack(spacing: 14) {
                    BreakdownBar(label: "Sleep", score: breakdown.sleepScore, color: RTColor.sleep, weight: "25%", metricType: .sleep, currentValue: data.sleepHours, history: history, source: selectedSource)
                    BreakdownBar(label: data.hrvIsRMSSD ? "RMSSD" : "HRV", score: breakdown.hrvScore, color: RTColor.hrv, weight: "25%", metricType: .hrv, currentValue: data.hrv, history: history, source: selectedSource)
                    BreakdownBar(label: "Recovery", score: breakdown.recoveryScore, color: RTColor.recovery, weight: "20%", metricType: .restingHR, currentValue: data.restingHeartRate, history: history, source: selectedSource)
                    BreakdownBar(label: "SpO2", score: breakdown.spo2Score, color: RTColor.optimal, weight: "5%", metricType: .bloodOxygen, currentValue: (data.bloodOxygen ?? 0) > 1.0 ? (data.bloodOxygen ?? 0) : (data.bloodOxygen ?? 0) * 100.0, history: history, source: selectedSource)
                    BreakdownBar(label: "Strain", score: breakdown.strainScore, color: RTColor.strain, weight: "15%", metricType: .activeCalories, currentValue: data.activeCalories, history: history, source: selectedSource)
                    BreakdownBar(label: "Consistency", score: breakdown.consistencyScore, color: RTColor.consistency, weight: "10%", metricType: .sleep, currentValue: data.sleepHours, history: history, source: selectedSource)
                }

                Divider()
                    .background(RTColor.divider)

                HStack {
                    Text("Total")
                        .font(RTFont.headline)
                    Spacer()
                    Text("\(breakdown.totalScore)")
                        .font(RTFont.metricValue)
                        .foregroundStyle(ScoreZone(score: breakdown.totalScore).color)
                }
            }
        }
    }

    // MARK: - Trend Section (Multi-metric)
    private func trendSection(history: [DailyHealthData]) -> some View {
        NavigationLink(destination: TrendDetailView(history: history)) {
            NativeCard {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        SectionHeader(title: "Trends")
                        Spacer()
                        TrendPeriodSelector(period: $trendPeriod)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(RTColor.tertiaryText)
                    }

                    if history.count >= 2 {
                        // Precompute chart points once so calculateBreakdown is not
                        // called per point per render (O(n^2) -> O(n) work).
                        let points: [TrendChartPoint] = history.map { data in
                            TrendChartPoint(
                                date: data.date,
                                readinessScore: ReadinessCalculator.calculateBreakdown(from: data, history: history).totalScore,
                                hrvNormalized: min(100, Double(data.hrv) * 2),
                                rhrNormalized: max(0, 100 - Double(data.restingHeartRate - 40) * 2)
                            )
                        }

                        // Multi-metric chart
                        Chart(points) { point in
                            // Readiness score line
                            LineMark(
                                x: .value("Date", point.date, unit: .day),
                                y: .value("Score", point.readinessScore)
                            )
                            .foregroundStyle(RTColor.optimal)
                            .interpolationMethod(.catmullRom)
                            .lineStyle(StrokeStyle(lineWidth: 2.5))

                            // HRV line (scaled to 0-100)
                            LineMark(
                                x: .value("Date", point.date, unit: .day),
                                y: .value("HRV", point.hrvNormalized)
                            )
                            .foregroundStyle(RTColor.hrv.opacity(0.6))
                            .interpolationMethod(.catmullRom)
                            .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 4]))

                            // RHR line (scaled: lower is better, invert)
                            LineMark(
                                x: .value("Date", point.date, unit: .day),
                                y: .value("RHR", point.rhrNormalized)
                            )
                            .foregroundStyle(RTColor.strain.opacity(0.6))
                            .interpolationMethod(.catmullRom)
                            .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [2, 2]))

                            AreaMark(
                                x: .value("Date", point.date, unit: .day),
                                y: .value("Score", point.readinessScore)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [RTColor.optimal.opacity(0.2), RTColor.optimal.opacity(0.0)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .interpolationMethod(.catmullRom)
                        }
                        .frame(height: 200)
                        .chartYScale(domain: 0...100)

                        // Legend
                        HStack(spacing: 16) {
                            LegendDot(label: "Readiness", color: RTColor.optimal, style: .solid)
                            LegendDot(label: "HRV", color: RTColor.hrv, style: .dashed)
                            LegendDot(label: "RHR", color: RTColor.strain, style: .dotted)
                        }
                        .padding(.top, 8)
                    } else {
                        Text("Need more data")
                            .font(.subheadline)
                            .foregroundStyle(RTColor.secondaryText)
                            .frame(height: 200)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Loading State
    private var loadingView: some View {
        VStack(spacing: AppleTheme.sectionSpacing) {
            // Hero skeleton
            NativeCard {
                VStack(spacing: 20) {
                    Circle()
                        .fill(RTColor.surfaceHighlight)
                        .frame(width: 200, height: 200)

                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(RTColor.surfaceHighlight)
                        .frame(width: 220, height: 16)

                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(RTColor.surfaceHighlight)
                        .frame(width: 160, height: 12)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            }
            .shimmer()

            // Card skeletons
            ForEach(0..<3, id: \.self) { _ in
                NativeCard {
                    VStack(alignment: .leading, spacing: 12) {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(RTColor.surfaceHighlight)
                            .frame(width: 120, height: 14)

                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(RTColor.surfaceHighlight)
                            .frame(height: 32)
                    }
                }
                .shimmer()
            }

            Text("Loading your health data...")
                .font(.caption)
                .foregroundStyle(RTColor.secondaryText)
        }
    }

    // MARK: - No Data
    private var noDataView: some View {
        VStack(spacing: 24) {
            Image(systemName: "arrow.down.heart.fill")
                .font(.system(size: 64))
                .foregroundStyle(RTColor.tertiaryText)

            VStack(spacing: 8) {
                Text("No data yet")
                    .font(RTFont.title)
                    .foregroundStyle(RTColor.primaryText)

                Text(selectedSource == .appleWatch
                     ? "Pull down to refresh your HealthKit data"
                     : "Connect your Fitbit account")
                    .font(.subheadline)
                    .foregroundStyle(RTColor.secondaryText)
                    .multilineTextAlignment(.center)
            }

            Button(action: {
                Haptic.press()
                Task {
                    if selectedSource == .appleWatch {
                        await healthKit.requestAuthorization()
                        await performRefresh()
                    } else if let url = fitbit.authURL {
                        openURL(url)
                    }
                }
            }) {
                Label(selectedSource == .appleWatch ? "Grant HealthKit Access" : "Connect Fitbit",
                      systemImage: "link")
                .font(.subheadline.weight(.semibold))
                .padding()
                .frame(maxWidth: .infinity)
                .background(RTColor.optimal)
                .foregroundStyle(.black)
                .clipShape(RoundedRectangle(cornerRadius: AppleTheme.cornerRadiusMedium, style: .continuous))
            }
        }
        .padding(.top, 80)
    }

    // MARK: - Helpers
    private func initialLoadIfNeeded() async {
        guard latestData == nil, !isRefreshing else { return }
        isRefreshing = true
        await refreshData()
        isRefreshing = false
        lastSyncDate = latestData?.date ?? lastSyncDate
    }

    private func performRefresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        Haptic.press()
        await refreshData()
        dismissedError = nil
        isRefreshing = false
        lastSyncDate = latestData?.date ?? Date()
        Haptic.success()
    }

    private func refreshData() async {
        if selectedSource == .appleWatch {
            await healthKit.fetchTodayData()
            // Also refresh historical data in case new data appeared in HealthKit
            await healthKit.fetchHistoricalData(days: 30)
        } else {
            await fitbit.fetchTodayData()
        }
    }

    private func bodyActivitySection(data: DailyHealthData) -> some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "Body & activity")

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    bodyStat(title: "Steps", value: "\(data.steps)", icon: "figure.walk")
                    bodyStat(title: "Activity", value: "\(data.workoutMinutes) min", icon: "flame.fill")
                    bodyStat(title: "Calories", value: "\(Int(data.activeCalories))", icon: "bolt.fill")
                    bodyStat(
                        title: "SpO2",
                        value: spo2Display(data.bloodOxygen),
                        icon: "lungs.fill"
                    )
                    bodyStat(
                        title: "Water",
                        value: data.nutrition.waterLiters.map { String(format: "%.1f L", $0) } ?? "—",
                        icon: "drop.fill"
                    )
                    bodyStat(
                        title: "Caffeine",
                        value: data.nutrition.caffeineMg.map { "\(Int($0)) mg" } ?? "—",
                        icon: "cup.and.saucer.fill"
                    )
                    bodyStat(
                        title: "Protein",
                        value: data.nutrition.proteinGrams.map { "\(Int($0)) g" } ?? "—",
                        icon: "fork.knife"
                    )
                    if UserSettings.load().trackMenstrualCycle {
                        bodyStat(
                            title: "Cycle",
                            value: data.menstrualFlow ? "Flow reported" : "No flow",
                            icon: "circle.lefthalf.filled"
                        )
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Body and activity")
        .accessibilityIdentifier(SurfaceID.bodyActivitySection)
    }

    private func bodyStat(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(RTColor.secondaryText)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(RTColor.secondaryText)
            }
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(RTColor.primaryText)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func spo2Display(_ value: Double?) -> String {
        guard let value, value > 0 else { return "—" }
        let percent = value > 1.0 ? value : value * 100
        return String(format: "%.0f%%", percent)
    }

    static func healthKitSourceLabel(_ raw: String) -> String {
        raw.localizedCaseInsensitiveContains("whoop") ? "WHOOP via Apple Health" : raw
    }

    private func trendFor(_ value: Double, baseline: Double, higherIsBetter: Bool) -> TrendDirection {
        let threshold = baseline * 0.05
        if abs(value - baseline) < threshold { return .flat }
        let isUp = value > baseline
        return (isUp && higherIsBetter) || (!isUp && !higherIsBetter) ? .up : .down
    }
}

// MARK: - Supporting Views

struct CheckInStatusCard: View {
    let label: String
    let icon: String
    let isDone: Bool
    let color: Color

    var body: some View {
        NativeCard {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(isDone ? color : RTColor.tertiaryText)

                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(RTColor.primaryText)
                    Text(isDone ? "Done" : "Pending")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(isDone ? color : RTColor.tertiaryText)
                }

                Spacer()

                Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(isDone ? color : RTColor.surfaceHighlight)
            }
        }
    }
}

struct BreakdownBar: View {
    let label: String
    let score: Int
    let color: Color
    let weight: String
    let metricType: MetricType
    let currentValue: Double
    let history: [DailyHealthData]
    let source: DataSource

    var body: some View {
        NavigationLink(destination: AdvancedMetricDetailView(
            metric: metricType,
            currentValue: currentValue,
            history: history,
            source: source
        )) {
            HStack(spacing: 12) {
                Text(label)
                    .font(RTFont.body)
                    .foregroundStyle(RTColor.primaryText)
                    .frame(width: 70, alignment: .leading)

                Text(weight)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(RTColor.tertiaryText)
                    .frame(width: 30)

                AnimatedProgressBar(
                    progress: Double(score) / 100,
                    color: color,
                    height: 8
                )

                Text("\(score)")
                    .font(RTFont.metricValue)
                    .foregroundStyle(color)
                    .frame(minWidth: 28, idealWidth: 36, maxWidth: 50, alignment: .trailing)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .buttonStyle(.plain)
    }
}

struct StageLabel: View {
    let label: String
    let percent: Double
    let optimal: String
    let isOptimal: Bool

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(RTColor.secondaryText)

            Text("\(Int(percent * 100))%")
                .font(RTFont.metricValue)
                .foregroundStyle(RTColor.primaryText)

            Text(optimal)
                .font(.caption2.weight(.medium))
                .foregroundStyle(isOptimal ? RTColor.optimal : RTColor.tertiaryText)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Trend Chart Point
/// Precomputed trend chart point so readiness/strain/recovery values are
/// calculated once per render instead of per chart mark evaluation.
struct TrendChartPoint: Identifiable {
    var id: Date { date }
    let date: Date
    let readinessScore: Int
    let hrvNormalized: Double
    let rhrNormalized: Double
}

// MARK: - Legend Dot
struct LegendDot: View {
    let label: String
    let color: Color
    let style: LineStyle

    enum LineStyle {
        case solid, dashed, dotted
    }

    var body: some View {
        HStack(spacing: 6) {
            Rectangle()
                .fill(color)
                .frame(width: 16, height: style == .solid ? 3 : 2)
                .overlay(
                    Rectangle()
                        .stroke(color, style: style == .dashed ? StrokeStyle(lineWidth: 2, dash: [3, 3]) : style == .dotted ? StrokeStyle(lineWidth: 2, dash: [2, 2]) : StrokeStyle())
                )

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(RTColor.secondaryText)
        }
    }
}

// MARK: - Dual Score Card
struct DualScoreCard: View {
    let label: String
    let score: Int
    let icon: String
    let color: Color

    var body: some View {
        NativeCard {
            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(color)
                    Text(label)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(RTColor.secondaryText)
                }

                Text("\(score)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(ScoreZone(score: score).color)
                    .monospacedDigit()

                Text(ScoreZone(score: score).label)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(RTColor.tertiaryText)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
