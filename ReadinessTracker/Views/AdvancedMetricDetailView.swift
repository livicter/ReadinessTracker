import SwiftUI
import Charts

/// Enhanced metric detail view with Apple-native UI and real data science analysis.
struct AdvancedMetricDetailView: View {
    let metric: MetricType
    let currentValue: Double
    let history: [DailyHealthData]
    let source: DataSource
    
    @State private var selectedPeriod: TrendPeriod = .week
    @State private var showBaselineBands = true
    @State private var showMovingAverage = true
    @State private var showOutliers = true
    @Environment(\.dismiss) private var dismiss
    
    var filteredHistory: [(date: Date, value: Double)] {
        let days = selectedPeriod.rawValue
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        return history
            .filter { $0.date >= cutoff }
            .sorted { $0.date < $1.date }
            .map { ($0.date, metricValue(for: $0)) }
    }
    
    var analyzedData: [AnalyzedDataPoint] {
        TrendAnalysisEngine.analyze(history: filteredHistory, metric: metric)
    }
    
    var baseline: Double {
        analyzedData.first?.baseline ?? currentValue
    }
    
    var stdDev: Double {
        let values = filteredHistory.map { $0.value }
        return TrendAnalysisEngine.standardDeviation(values: values)
    }
    
    var latestAnalysis: AnalyzedDataPoint? {
        analyzedData.last
    }
    
    var trendClassification: TrendAnalysisEngine.TrendStrength? {
        guard let analysis = latestAnalysis,
              let slope = analysis.trendSlope,
              let r2 = analysis.trendRSquared else { return nil }
        return TrendAnalysisEngine.classifyTrend(slope: slope, rSquared: r2, metric: metric)
    }
    
    // MARK: - Computed trend for badge
    var currentTrend: TrendDirection {
        guard let analysis = latestAnalysis else { return .flat }
        let deviation = analysis.percentDeviation
        let threshold = 0.05
        if abs(deviation) < threshold { return .flat }
        let isUp = deviation > 0
        return (isUp && metric.higherIsBetter) || (!isUp && !metric.higherIsBetter) ? .up : .down
    }
    
    var trendBadgeValue: String {
        guard let analysis = latestAnalysis else { return "No trend" }
        let pct = abs(analysis.percentDeviation) * 100
        let sign = analysis.percentDeviation >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.0f", pct))%"
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: AppleTheme.sectionSpacing) {
                // Apple-style hero with large value and trend badge
                heroSection
                
                // Native period selector with matchedGeometryEffect
                NativePeriodSelector(selectedPeriod: $selectedPeriod)
                    .padding(.horizontal, 4)
                    .onChange(of: selectedPeriod) { newValue in
                        Haptic.selectionChanged()
                    }
                
                // Toggle controls
                toggleControls
                
                // Advanced chart with native tooltip
                if !analyzedData.isEmpty {
                    NativeCard {
                        AdvancedMetricChartView(
                            metric: metric,
                            analyzedData: analyzedData,
                            showBaselineBands: showBaselineBands,
                            showMovingAverage: showMovingAverage,
                            showOutliers: showOutliers
                        )
                    }
                } else {
                    NativeCard {
                        VStack(spacing: 12) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 40))
                                .foregroundStyle(RTColor.surfaceHighlight)

                            Text("Not Enough Data")
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(RTColor.primaryText)

                            Text("Need at least 2 days of data in this period for analysis")
                                .font(.caption)
                                .foregroundStyle(RTColor.tertiaryText)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                    }
                }
                
                // Outlier callouts section
                outlierSection
                
                // Statistics grid
                statsSection
                
                // Distribution histogram
                if filteredHistory.count >= 5 {
                    DistributionHistogramView(
                        history: filteredHistory,
                        metric: metric
                    )
                }
                
                // Smart insights
                if !filteredHistory.isEmpty {
                    SmartInsightsView(
                        metric: metric,
                        history: filteredHistory,
                        currentValue: currentValue
                    )
                }
                
                // Recovery trajectory
                if filteredHistory.count >= 7 {
                    RecoveryTrajectoryView(
                        history: filteredHistory,
                        metric: metric
                    )
                }
                
                // Weekly pattern
                if filteredHistory.count >= 7 {
                    WeeklyPatternView(
                        history: filteredHistory,
                        metric: metric
                    )
                }
                
                // Correlations
                if history.count >= 7 {
                    correlationSection
                }
                
                // HealthKit info
                if source == .appleWatch {
                    healthKitInfoSection
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(AppBackground())
        .navigationTitle(metric.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(RTColor.background, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .onAppear {
            Haptic.prepare()
        }
    }
    
    // MARK: - Hero Section (Apple Health style)
    
    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Date range
            Text(dateRangeLabel)
                .font(.subheadline)
                .foregroundStyle(RTColor.secondaryText)
            
            // Large value
            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text(formattedValue(currentValue))
                    .font(AppleTheme.heroValue)
                    .foregroundStyle(RTColor.primaryText)
                    .minimumScaleFactor(0.5)
                
                Text(metric.unit)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
            }
            
            // Trend badge
            TrendBadge(direction: currentTrend, value: trendBadgeValue)
            
            // Zone indicator
            if let zone = metric.zone(for: currentValue) {
                HStack(spacing: 8) {
                    Text(zone.label)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(zone.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(zone.color.opacity(0.12))
                        .clipShape(Capsule())
                    
                    Text(zone.description)
                        .font(.caption)
                        .foregroundStyle(RTColor.secondaryText)
                    
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 4)
    }
    
    private var dateRangeLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let end = Date()
        let start = Calendar.current.date(byAdding: .day, value: -selectedPeriod.rawValue, to: end)!
        return "\(formatter.string(from: start)) – \(formatter.string(from: end))"
    }
    
    // MARK: - Toggle Controls
    
    private var toggleControls: some View {
        HStack(spacing: 12) {
            ToggleChip(label: "Baseline Bands", isOn: $showBaselineBands)
            ToggleChip(label: "Moving Avg", isOn: $showMovingAverage)
            ToggleChip(label: "Outliers", isOn: $showOutliers)
        }
    }
    
    // MARK: - Outlier Section
    
    private var outlierSection: some View {
        let outliers = analyzedData.filter { $0.isOutlier }
        guard !outliers.isEmpty else { return AnyView(EmptyView()) }
        
        return AnyView(
            VStack(alignment: .leading, spacing: 12) {
                NativeSectionHeader(title: "Highlights", action: nil)
                    .padding(.horizontal, 4)
                
                VStack(spacing: 8) {
                    ForEach(outliers.prefix(3)) { point in
                        let type: OutlierCallout.OutlierType = point.zScore > 0 ? .high : .low
                        let dateStr = point.date.formatted(.dateTime.month(.abbreviated).day())
                        let deviationStr = "\(point.zScore > 0 ? "+" : "")\(String(format: "%.1f", point.zScore))σ"
                        
                        OutlierCallout(
                            type: type,
                            value: "\(formattedValue(point.rawValue)) \(metric.unit)",
                            date: dateStr,
                            deviation: deviationStr
                        )
                    }
                }
            }
        )
    }
    
    // MARK: - Stats Section
    
    private var statsSection: some View {
        let values = filteredHistory.map { $0.value }
        let avg = TrendAnalysisEngine.mean(values: values)
        let best = values.max() ?? 0
        let worst = values.min() ?? 0
        let cv = TrendAnalysisEngine.coefficientOfVariation(values: values)
        
        return VStack(alignment: .leading, spacing: 12) {
            NativeSectionHeader(title: "Statistics", action: nil)
                .padding(.horizontal, 4)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StatGridItem(
                    label: "Average",
                    value: formattedValue(avg),
                    unit: metric.unit,
                    trend: currentTrend
                )
                StatGridItem(
                    label: "Best",
                    value: formattedValue(best),
                    unit: metric.unit,
                    trend: nil
                )
                StatGridItem(
                    label: "Worst",
                    value: formattedValue(worst),
                    unit: metric.unit,
                    trend: nil
                )
                StatGridItem(
                    label: "Volatility",
                    value: "\(Int(cv * 100))%",
                    unit: "CV",
                    trend: nil
                )
            }
        }
    }
    
    // MARK: - Correlation Section
    
    private var correlationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            NativeSectionHeader(title: "Correlations", action: nil)
                .padding(.horizontal, 4)
            
            let otherMetrics = MetricType.allCases.filter { $0 != metric }
            
            ForEach(otherMetrics, id: \.self) { otherMetric in
                let xValues = history.map { metricValue(for: $0) }
                let yValues = history.map { metricValue($0, for: otherMetric) }
                let corr = TrendAnalysisEngine.pearsonCorrelation(x: xValues, y: yValues)
                
                if abs(corr) > 0.2 {
                    MetricCorrelationView(
                        history: history,
                        xMetric: metric,
                        yMetric: otherMetric
                    )
                }
            }
        }
    }
    
    // MARK: - HealthKit Info
    
    private var healthKitInfoSection: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(RTColor.caution)
                    
                    Text("About This Data")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(RTColor.primaryText)
                }
                
                Text("HealthKit only stores data from when you first granted permission. Apple does not retroactively backfill historical health data when you install a new app.")
                    .font(.subheadline)
                    .foregroundStyle(RTColor.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                
                VStack(alignment: .leading, spacing: 8) {
                    InfoRow(icon: "checkmark.circle.fill", text: "Data from today forward is saved automatically")
                    InfoRow(icon: "checkmark.circle.fill", text: "Your data stays in Apple Health even if you delete this app")
                    InfoRow(icon: "xmark.circle.fill", text: "Past data before app install is not accessible via HealthKit")
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func metricValue(for data: DailyHealthData) -> Double {
        switch metric {
        case .sleep: return data.sleepHours
        case .hrv: return data.hrv
        case .restingHR: return data.restingHeartRate
        case .activeCalories: return data.activeCalories
        case .bloodOxygen: return data.bloodOxygen ?? 0
        }
    }
    
    private func metricValue(_ data: DailyHealthData, for metric: MetricType) -> Double {
        switch metric {
        case .sleep: return data.sleepHours
        case .hrv: return data.hrv
        case .restingHR: return data.restingHeartRate
        case .activeCalories: return data.activeCalories
        case .bloodOxygen: return data.bloodOxygen ?? 0
        }
    }
    
    private func formattedValue(_ value: Double) -> String {
        switch metric {
        case .sleep:
            return String(format: "%.1f", value)
        case .hrv, .restingHR, .activeCalories, .bloodOxygen:
            return "\(Int(value))"
        }
    }
}

// MARK: - Toggle Chip (updated for native style)

struct ToggleChip: View {
    let label: String
    @Binding var isOn: Bool
    
    var body: some View {
        Button(action: {
            Haptic.rigid()
            isOn.toggle()
        }) {
            HStack(spacing: 6) {
                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 12))
                    .foregroundStyle(isOn ? RTColor.optimal : RTColor.tertiaryText)
                
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(isOn ? .white : RTColor.secondaryText)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isOn ? RTColor.optimal.opacity(0.15) : RTColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
