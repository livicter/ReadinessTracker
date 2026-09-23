import SwiftUI
import Charts

/// Full-screen trend detail — History Browse Trends / Dashboard Trends.
/// Health Browse parity: period chips, summary Avg/Min/Max/Change, drag scrub.
struct TrendDetailView: View {
    let history: [DailyHealthData]
    
    @State private var selectedPeriod: TrendPeriod = .week
    @State private var selectedMetrics: Set<MetricToggle> = [.readiness, .sleep, .hrv]
    /// Readiness scores precomputed once per history change — avoids O(n²) recalculation per chart point.
    @State private var readinessScores: [UUID: Int] = [:]
    @State private var selectedScrubDay: DailyHealthData?
    @State private var lastHapticID: DailyHealthData.ID?
    /// Honest #258: Trends Baseline Bands ±2σ (classic #251 dual completion).
    @State private var showBaselineBands = true
    /// Honest #259: Trends rollingVolatility strip (classic #248 / Advanced #240 parity).
    @State private var showVolatility = true
    /// Honest #260: Trends momentum strip (classic #248 / Advanced #241 parity).
    @State private var showMomentum = true
    /// Honest #261: Trends Day Δ / rateOfChange strip (classic #248 triad complete).
    @State private var showRateOfChange = true
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    enum MetricToggle: String, CaseIterable, Identifiable {
        case readiness = "Readiness"
        case sleep = "Sleep"
        case hrv = "HRV"
        case rhr = "Resting HR"
        case calories = "Calories"
        
        var id: String { rawValue }
        
        var color: Color {
            switch self {
            case .readiness: return RTColor.optimal
            case .sleep: return RTColor.sleep
            case .hrv: return RTColor.hrv
            case .rhr: return RTColor.strain
            case .calories: return RTColor.caution
            }
        }
        
        var icon: String {
            switch self {
            case .readiness: return "gauge.with.dots.needle.67percent"
            case .sleep: return "bed.double.fill"
            case .hrv: return "waveform.path.ecg"
            case .rhr: return "heart.fill"
            case .calories: return "flame.fill"
            }
        }
    }
    
    var filteredHistory: [DailyHealthData] {
        let days = selectedPeriod.rawValue
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        return history
            .filter { $0.date >= cutoff }
            .sorted { $0.date < $1.date }
    }
    
    private func readinessScore(for day: DailyHealthData) -> Int {
        ReadinessCalculator.calculateBreakdown(from: day, history: history).totalScore
    }
    
    private func precomputeReadinessScores() {
        readinessScores = Dictionary(uniqueKeysWithValues: history.map { ($0.id, readinessScore(for: $0)) })
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: AppleTheme.sectionSpacing) {
                // Period selector (Health Browse chips: 7D / 30D / 90D / 1Y)
                periodSelector
                    .slideIn(delay: 0)
                
                // Summary stats for primary metric (Avg / Min / Max / Change %)
                summaryStatsRow
                    .slideIn(delay: 0.03)

                // Honest #255: elevate unused classifyTrend on Trends primary series.
                if let strength = trendClassification {
                    trendsClassifyTrendCallout(strength)
                        .slideIn(delay: 0.04)
                }
                
                // Metric toggles
                metricToggles
                    .slideIn(delay: 0.05)
                
                // Main multi-metric chart + scrub
                mainChart
                    .slideIn(delay: 0.1)

                // Depth timeline for primary metric
                depthTimelineSection
                    .slideIn(delay: 0.12)

                // Honest #257: OutlierCallout list (classic #251 / Advanced Highlights parity).
                trendsOutlierSection
                    .slideIn(delay: 0.125)

                // Honest #255: Distribution histogram (Metric Detail parity, ≥5 days).
                if depthTimelinePoints.count >= 5 {
                    DistributionHistogramView(
                        history: depthTimelinePoints,
                        metric: scrubAnalysisMetric
                    )
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier(SurfaceID.trendsHistogram)
                    .slideIn(delay: 0.13)
                }
                
                // Individual metric cards
                metricCards
                    .slideIn(delay: 0.15)
                
                // Correlation matrix
                if filteredHistory.count >= 5 {
                    correlationSection
                        .slideIn(delay: 0.2)
                }
            }
            .padding(.horizontal, AppleTheme.horizontalMargin)
            .padding(.vertical, 12)
        }
        .background(AppBackground())
        .onAppear { precomputeReadinessScores() }
        .onChange(of: history) { _ in precomputeReadinessScores() }
        .onChange(of: selectedPeriod) { _ in
            selectedScrubDay = nil
            lastHapticID = nil
        }
        .accessibilityIdentifier(SurfaceID.trendsDetail)
        .navigationTitle("Trends")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(RTColor.background, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
    }
    
    // MARK: - Period Selector
    private var periodSelector: some View {
        NativePeriodSelector(selectedPeriod: $selectedPeriod)
    }
    
    // MARK: - Summary Stats (Health Browse)
    private var summaryStatsRow: some View {
        let values = primarySeriesValues
        let avg = values.isEmpty ? 0 : values.reduce(0, +) / Double(values.count)
        let minV = values.min() ?? 0
        let maxV = values.max() ?? 0
        let change = periodChangePercent(values)
        // Honest #256: elevate unused coefficientOfVariation (classic/Advanced stats parity).
        let cv = values.count >= 2
            ? TrendAnalysisEngine.coefficientOfVariation(values: values)
            : 0
        let cvLabel = values.count >= 2 ? "\(Int(cv * 100))%" : "—"
        return NativeCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(primaryDepthMetric.rawValue)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(RTColor.primaryText)
                    Text(selectedPeriod.label)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(RTColor.tertiaryText)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(RTColor.surfaceHighlight)
                        .clipShape(Capsule())
                    Spacer()
                    Text(depthTimelineUnit.isEmpty ? "score" : depthTimelineUnit)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(RTColor.tertiaryText)
                }
                
                HStack(spacing: 0) {
                    summaryStatCell(label: "Avg", value: formattedSummary(avg))
                    summaryStatCell(label: "Min", value: formattedSummary(minV))
                    summaryStatCell(label: "Max", value: formattedSummary(maxV))
                    summaryStatCell(
                        label: "Change",
                        value: change.map { String(format: "%+.0f%%", $0) } ?? "—",
                        accent: changeAccent(change)
                    )
                }

                // Honest #256: Volatility CV% (coefficientOfVariation) — Metric Detail #254 parity.
                HStack(spacing: 0) {
                    summaryStatCell(label: "Volatility", value: cvLabel)
                        .accessibilityIdentifier(SurfaceID.trendsStatsCV)
                        .accessibilityLabel("Volatility coefficient of variation")
                    Spacer(minLength: 0)
                    Spacer(minLength: 0)
                    Spacer(minLength: 0)
                }
            }
        }
        .accessibilityIdentifier(SurfaceID.trendsSummary)
        .accessibilityElement(children: .contain)
    }
    
    private func summaryStatCell(label: String, value: String, accent: Color? = nil) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(RTColor.tertiaryText)
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(accent ?? RTColor.primaryText)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var primarySeriesValues: [Double] {
        depthTimelinePoints.map(\.value)
    }
    
    private func periodChangePercent(_ values: [Double]) -> Double? {
        guard values.count >= 2, let first = values.first, abs(first) > 0.0001 else { return nil }
        let last = values.last!
        return ((last - first) / abs(first)) * 100
    }
    
    private func changeAccent(_ change: Double?) -> Color? {
        guard let change else { return nil }
        if abs(change) < 1 { return RTColor.secondaryText }
        // Readiness / sleep / HRV / calories: up is good; RHR: down is good.
        let upIsGood = primaryDepthMetric != .rhr
        let improved = upIsGood ? change > 0 : change < 0
        return improved ? RTColor.optimal : RTColor.warning
    }
    
    private func formattedSummary(_ value: Double) -> String {
        if value == floor(value) { return "\(Int(value))" }
        return String(format: "%.1f", value)
    }
    
    // MARK: - Metric Toggles
    private var metricToggles: some View {
        FlowLayout(spacing: 8) {
            ForEach(MetricToggle.allCases) { metric in
                Button {
                    Haptic.selectionChanged()
                    if selectedMetrics.contains(metric) {
                        if selectedMetrics.count > 1 {
                            selectedMetrics.remove(metric)
                        }
                    } else {
                        selectedMetrics.insert(metric)
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: metric.icon)
                            .font(.system(size: 12))
                        Text(metric.rawValue)
                            .font(.caption.weight(.medium))
                    }
                    .foregroundStyle(selectedMetrics.contains(metric) ? metric.color.contrastingTextColor : RTColor.secondaryText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(selectedMetrics.contains(metric) ? metric.color : RTColor.surface)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Main Chart
    private var mainChart: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Multi-Metric Trend")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(RTColor.primaryText)
                    Spacer()
                    if selectedScrubDay == nil {
                        Text("Drag to inspect")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(RTColor.tertiaryText)
                    }
                }
                
                if filteredHistory.count >= 2 {
                    Chart {
                        ForEach(filteredHistory) { day in
                            if selectedMetrics.contains(.readiness) {
                                LineMark(
                                    x: .value("Date", day.date, unit: .day),
                                    y: .value("Readiness", readinessScores[day.id] ?? 0)
                                )
                                .foregroundStyle(MetricToggle.readiness.color)
                                .interpolationMethod(.catmullRom)
                                .lineStyle(StrokeStyle(lineWidth: 2.5))
                            }
                            
                            if selectedMetrics.contains(.sleep) {
                                let sleepNormalized = min(100, day.sleepHours * 12.5)
                                LineMark(
                                    x: .value("Date", day.date, unit: .day),
                                    y: .value("Sleep", sleepNormalized)
                                )
                                .foregroundStyle(MetricToggle.sleep.color.opacity(0.7))
                                .interpolationMethod(.catmullRom)
                                .lineStyle(StrokeStyle(lineWidth: 2, dash: [4, 4]))
                            }
                            
                            if selectedMetrics.contains(.hrv) {
                                let hrvNormalized = min(100, Double(day.hrv) * 2)
                                LineMark(
                                    x: .value("Date", day.date, unit: .day),
                                    y: .value("HRV", hrvNormalized)
                                )
                                .foregroundStyle(MetricToggle.hrv.color.opacity(0.7))
                                .interpolationMethod(.catmullRom)
                                .lineStyle(StrokeStyle(lineWidth: 2, dash: [2, 2]))
                            }
                            
                            if selectedMetrics.contains(.rhr) {
                                let rhrNormalized = max(0, 100 - Double(day.restingHeartRate - 40) * 2)
                                LineMark(
                                    x: .value("Date", day.date, unit: .day),
                                    y: .value("RHR", rhrNormalized)
                                )
                                .foregroundStyle(MetricToggle.rhr.color.opacity(0.7))
                                .interpolationMethod(.catmullRom)
                                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [6, 3]))
                            }
                            
                            if selectedMetrics.contains(.calories) {
                                let calNormalized = min(100, day.activeCalories / 15)
                                LineMark(
                                    x: .value("Date", day.date, unit: .day),
                                    y: .value("Calories", calNormalized)
                                )
                                .foregroundStyle(MetricToggle.calories.color.opacity(0.7))
                                .interpolationMethod(.catmullRom)
                                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [1, 3]))
                            }
                        }
                        
                        if let selected = selectedScrubDay {
                            RuleMark(x: .value("Selected", selected.date))
                                .foregroundStyle(RTColor.primaryText.opacity(0.35))
                                .lineStyle(StrokeStyle(lineWidth: 1))
                            
                            PointMark(
                                x: .value("Selected", selected.date, unit: .day),
                                y: .value("Value", scrubNormalizedValue(for: selected))
                            )
                            .foregroundStyle(primaryDepthMetric.color)
                            .symbolSize(120)
                        }
                    }
                    .frame(height: 260)
                    .chartYScale(domain: 0...100)
                    .chartXAxis {
                        AxisMarks(values: .stride(by: selectedPeriod == .week ? .day : .weekOfYear)) { _ in
                            AxisGridLine()
                            AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                        }
                    }
                    .chartBackground { proxy in
                        scrubAnnotationOverlay(proxy: proxy)
                    }
                    .chartOverlay { proxy in
                        scrubOverlay(proxy: proxy)
                    }
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier(SurfaceID.trendsChartScrub)
                    
                    // Legend
                    HStack(spacing: 12) {
                        ForEach(Array(selectedMetrics.sorted { $0.rawValue < $1.rawValue }), id: \.self) { metric in
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(metric.color)
                                    .frame(width: 8, height: 8)
                                Text(metric.rawValue)
                                    .font(.caption2)
                                    .foregroundStyle(RTColor.secondaryText)
                            }
                        }
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 40))
                            .foregroundStyle(RTColor.surfaceHighlight)

                        Text("Not Enough Data")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(RTColor.secondaryText)

                        Text("Need at least 2 days of data in this period to show trends")
                            .font(.caption)
                            .foregroundStyle(RTColor.tertiaryText)
                    }
                    .frame(height: 260)
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
    
    private func scrubNormalizedValue(for day: DailyHealthData) -> Double {
        switch primaryDepthMetric {
        case .readiness: return Double(readinessScores[day.id] ?? 0)
        case .sleep: return min(100, day.sleepHours * 12.5)
        case .hrv: return min(100, Double(day.hrv) * 2)
        case .rhr: return max(0, 100 - Double(day.restingHeartRate - 40) * 2)
        case .calories: return min(100, day.activeCalories / 15)
        }
    }
    
    private func scrubRawValue(for day: DailyHealthData) -> Double {
        switch primaryDepthMetric {
        case .readiness: return Double(readinessScores[day.id] ?? 0)
        case .sleep: return day.sleepHours
        case .hrv: return Double(day.hrv)
        case .rhr: return Double(day.restingHeartRate)
        case .calories: return day.activeCalories
        }
    }
    
    /// Map Trends primary toggle → MetricType for `analyze()` (metric unused for z/ROC series).
    private var scrubAnalysisMetric: MetricType {
        switch primaryDepthMetric {
        case .readiness: return .sleep  // polarity: higher-is-better composite score
        case .sleep: return .sleep
        case .hrv: return .hrv
        case .rhr: return .restingHR
        case .calories: return .activeCalories
        }
    }

    /// Honest #250: elevate unused AnalyzedDataPoint fields on Trends scrub.
    private var scrubAnalyzedData: [AnalyzedDataPoint] {
        TrendAnalysisEngine.analyze(history: depthTimelinePoints, metric: scrubAnalysisMetric)
    }

    /// Honest #255: elevate unused classifyTrend on Trends primary depth series.
    private var trendClassification: TrendAnalysisEngine.TrendStrength? {
        guard let analysis = scrubAnalyzedData.last,
              let slope = analysis.trendSlope,
              let r2 = analysis.trendRSquared else { return nil }
        return TrendAnalysisEngine.classifyTrend(slope: slope, rSquared: r2, metric: scrubAnalysisMetric)
    }

    private func trendsClassifyTrendCallout(_ strength: TrendAnalysisEngine.TrendStrength) -> some View {
        let r2 = scrubAnalyzedData.last?.trendRSquared
        return HStack(spacing: 8) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.caption.weight(.semibold))
                .foregroundStyle(strength.trendColor)
                .frame(width: 26, height: 26)
                .background(strength.trendColor.opacity(0.14))
                .clipShape(Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(strength.rawValue)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(strength.trendColor)
                if let r2 {
                    Text(String(format: "Regression fit R² %.2f", r2))
                        .font(.caption2)
                        .foregroundStyle(RTColor.secondaryText)
                } else {
                    Text("Linear trend vs period baseline")
                        .font(.caption2)
                        .foregroundStyle(RTColor.secondaryText)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(strength.trendColor.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(SurfaceID.trendsTrendStrength)
        .accessibilityLabel("Trend strength " + strength.rawValue)
    }

    /// Honest #257: elevate unused isOutlier via OutlierCallout list (up to 3).
    @ViewBuilder
    private var trendsOutlierSection: some View {
        let outliers = scrubAnalyzedData.filter(\.isOutlier)
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
                        let unitSuffix = depthTimelineUnit.isEmpty ? "" : " \(depthTimelineUnit)"
                        OutlierCallout(
                            type: type,
                            value: "\(formattedSummary(point.rawValue))\(unitSuffix)",
                            date: dateStr,
                            deviation: deviationStr
                        )
                    }
                }
                .accessibilityIdentifier(SurfaceID.trendsOutlierList)
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(SurfaceID.trendsOutliers)
            .accessibilityLabel("Outlier highlights")
        }
    }

    // MARK: - Trends Volatility strip (Honest #259)

    private var trendsVolatilityPoints: [(date: Date, cv: Double)] {
        scrubAnalyzedData.compactMap { point in
            guard let cv = point.volatility else { return nil }
            return (point.date, cv)
        }
    }

    private var trendsLatestVolatilityBand: (label: String, color: Color) {
        guard let cv = trendsVolatilityPoints.last?.cv else {
            return ("—", RTColor.secondaryText)
        }
        if cv >= 0.15 { return ("High", RTColor.warning) }
        if cv >= 0.08 { return ("Mild", RTColor.caution) }
        return ("Low", RTColor.optimal)
    }

    private var trendsVolatilityYDomain: ClosedRange<Double> {
        let vals = trendsVolatilityPoints.map(\.cv)
        let hi = max(vals.max() ?? 0.2, 0.2)
        return 0...(hi * 1.15)
    }

    private var trendsVolatilityStrip: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("7-Day Volatility")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
                Spacer()
                if let cv = trendsVolatilityPoints.last?.cv {
                    Text(String(format: "CV %.0f%% · %@", cv * 100, trendsLatestVolatilityBand.label))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(trendsLatestVolatilityBand.color)
                        .monospacedDigit()
                }
            }

            if !trendsVolatilityPoints.isEmpty {
                Chart {
                    RectangleMark(
                        yStart: .value("Low", 0),
                        yEnd: .value("LowTop", 0.08)
                    )
                    .foregroundStyle(RTColor.optimal.opacity(0.08))
                    RectangleMark(
                        yStart: .value("Mild", 0.08),
                        yEnd: .value("MildTop", 0.15)
                    )
                    .foregroundStyle(RTColor.caution.opacity(0.08))
                    RectangleMark(
                        yStart: .value("High", 0.15),
                        yEnd: .value("HighTop", trendsVolatilityYDomain.upperBound)
                    )
                    .foregroundStyle(RTColor.warning.opacity(0.08))

                    ForEach(Array(trendsVolatilityPoints.enumerated()), id: \.offset) { _, point in
                        AreaMark(
                            x: .value("Date", point.date, unit: .day),
                            y: .value("CV", point.cv)
                        )
                        .foregroundStyle(RTColor.caution.opacity(0.18))
                        .interpolationMethod(.catmullRom)

                        LineMark(
                            x: .value("Date", point.date, unit: .day),
                            y: .value("CV", point.cv)
                        )
                        .foregroundStyle(RTColor.caution)
                        .lineStyle(StrokeStyle(lineWidth: 1.5))
                        .interpolationMethod(.catmullRom)
                    }
                }
                .frame(height: 72)
                .chartYScale(domain: trendsVolatilityYDomain)
                .chartXAxis(.hidden)
                .chartYAxis {
                    AxisMarks(position: .leading, values: [0, 0.08, 0.15]) { value in
                        AxisGridLine().foregroundStyle(RTColor.divider)
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text("\(Int(v * 100))%")
                                    .font(.system(size: 9))
                                    .foregroundStyle(RTColor.tertiaryText)
                            }
                        }
                    }
                }
            } else {
                Text("Need ≥7 days for volatility")
                    .font(.caption)
                    .foregroundStyle(RTColor.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(height: 72)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(SurfaceID.trendsVolatility)
        .accessibilityLabel("Seven day rolling volatility")
    }

    // MARK: - Trends Momentum strip (Honest #260)

    private var trendsMomentumPoints: [(date: Date, mom: Double)] {
        scrubAnalyzedData.compactMap { point in
            guard let mom = point.momentum else { return nil }
            return (point.date, mom)
        }
    }

    private var trendsLatestMomentumBand: (label: String, color: Color) {
        guard let mom = trendsMomentumPoints.last?.mom else {
            return ("—", RTColor.secondaryText)
        }
        let improving: Bool
        if scrubAnalysisMetric.higherIsBetter {
            improving = mom > 0
        } else {
            improving = mom < 0
        }
        if abs(mom) < 0.05 { return ("Flat", RTColor.secondaryText) }
        if improving { return ("Rising", RTColor.optimal) }
        return ("Fading", RTColor.warning)
    }

    private var trendsMomentumYDomain: ClosedRange<Double> {
        let vals = trendsMomentumPoints.map(\.mom)
        let lo = min(vals.min() ?? -0.2, -0.2)
        let hi = max(vals.max() ?? 0.2, 0.2)
        let pad = max((hi - lo) * 0.1, 0.05)
        return (lo - pad)...(hi + pad)
    }

    private var trendsMomentumStrip: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("7-Day Momentum")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
                Spacer()
                if let mom = trendsMomentumPoints.last?.mom {
                    let sign = mom >= 0 ? "+" : ""
                    Text(String(format: "%@%.0f%% · %@", sign, mom * 100, trendsLatestMomentumBand.label))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(trendsLatestMomentumBand.color)
                        .monospacedDigit()
                }
            }

            if !trendsMomentumPoints.isEmpty {
                Chart {
                    RuleMark(y: .value("Zero", 0))
                        .foregroundStyle(RTColor.tertiaryText.opacity(0.6))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))

                    ForEach(Array(trendsMomentumPoints.enumerated()), id: \.offset) { _, point in
                        AreaMark(
                            x: .value("Date", point.date, unit: .day),
                            yStart: .value("Zero", 0),
                            yEnd: .value("Mom", point.mom)
                        )
                        .foregroundStyle(
                            (scrubAnalysisMetric.higherIsBetter ? point.mom >= 0 : point.mom <= 0)
                                ? RTColor.optimal.opacity(0.18)
                                : RTColor.warning.opacity(0.18)
                        )

                        LineMark(
                            x: .value("Date", point.date, unit: .day),
                            y: .value("Mom", point.mom)
                        )
                        .foregroundStyle(RTColor.hrv)
                        .lineStyle(StrokeStyle(lineWidth: 1.5))
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Date", point.date, unit: .day),
                            y: .value("Mom", point.mom)
                        )
                        .foregroundStyle(RTColor.hrv)
                        .symbolSize(20)
                    }
                }
                .frame(height: 72)
                .chartYScale(domain: trendsMomentumYDomain)
                .chartXAxis(.hidden)
                .chartYAxis {
                    AxisMarks(position: .leading, values: [trendsMomentumYDomain.lowerBound, 0, trendsMomentumYDomain.upperBound]) { value in
                        AxisGridLine().foregroundStyle(RTColor.divider)
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text("\(Int(v * 100))%")
                                    .font(.system(size: 9))
                                    .foregroundStyle(RTColor.tertiaryText)
                            }
                        }
                    }
                }
            } else {
                Text("Need ≥8 days for momentum")
                    .font(.caption)
                    .foregroundStyle(RTColor.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(height: 72)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(SurfaceID.trendsMomentum)
        .accessibilityLabel("Seven day momentum")
    }

    // MARK: - Trends Day Δ strip (Honest #261)

    private var trendsROCPoints: [(date: Date, roc: Double)] {
        scrubAnalyzedData.compactMap { point in
            guard let roc = point.rateOfChange else { return nil }
            return (point.date, roc)
        }
    }

    private var trendsLatestROCBand: (label: String, color: Color) {
        guard let roc = trendsROCPoints.last?.roc else {
            return ("—", RTColor.secondaryText)
        }
        let improving: Bool
        if scrubAnalysisMetric.higherIsBetter {
            improving = roc > 0
        } else {
            improving = roc < 0
        }
        // Tighter bands than momentum — daily noise is larger.
        if abs(roc) < 0.03 { return ("Flat", RTColor.secondaryText) }
        if improving { return ("Up", RTColor.optimal) }
        return ("Down", RTColor.warning)
    }

    private var trendsROCYDomain: ClosedRange<Double> {
        let vals = trendsROCPoints.map(\.roc)
        let lo = min(vals.min() ?? -0.25, -0.25)
        let hi = max(vals.max() ?? 0.25, 0.25)
        let pad = max((hi - lo) * 0.1, 0.05)
        return (lo - pad)...(hi + pad)
    }

    private var trendsDayDeltaStrip: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Day-over-Day Change")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
                Spacer()
                if let roc = trendsROCPoints.last?.roc {
                    let sign = roc >= 0 ? "+" : ""
                    Text(String(format: "%@%.0f%% · %@", sign, roc * 100, trendsLatestROCBand.label))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(trendsLatestROCBand.color)
                        .monospacedDigit()
                }
            }

            if !trendsROCPoints.isEmpty {
                Chart {
                    RuleMark(y: .value("Zero", 0))
                        .foregroundStyle(RTColor.tertiaryText.opacity(0.6))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))

                    ForEach(Array(trendsROCPoints.enumerated()), id: \.offset) { _, point in
                        BarMark(
                            x: .value("Date", point.date, unit: .day),
                            y: .value("ROC", point.roc)
                        )
                        .foregroundStyle(
                            (scrubAnalysisMetric.higherIsBetter ? point.roc >= 0 : point.roc <= 0)
                                ? RTColor.optimal.opacity(0.75)
                                : RTColor.warning.opacity(0.75)
                        )
                        .cornerRadius(2)
                    }
                }
                .frame(height: 72)
                .chartYScale(domain: trendsROCYDomain)
                .chartXAxis(.hidden)
                .chartYAxis {
                    AxisMarks(position: .leading, values: [trendsROCYDomain.lowerBound, 0, trendsROCYDomain.upperBound]) { value in
                        AxisGridLine().foregroundStyle(RTColor.divider)
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text("\(Int(v * 100))%")
                                    .font(.system(size: 9))
                                    .foregroundStyle(RTColor.tertiaryText)
                            }
                        }
                    }
                }
            } else {
                Text("Need ≥2 days for day-over-day change")
                    .font(.caption)
                    .foregroundStyle(RTColor.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(height: 72)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(SurfaceID.trendsDayDelta)
        .accessibilityLabel("Day over day rate of change")
    }

    private func scrubAnnotationOverlay(proxy: ChartProxy) -> some View {
        GeometryReader { geometry in
            if let selected = selectedScrubDay {
                let xPos = proxy.position(forX: selected.date) ?? 0
                let yPos = proxy.position(forY: scrubNormalizedValue(for: selected)) ?? 0
                let valueText = formattedSummary(scrubRawValue(for: selected))
                // Honest #250: mirror Metric Detail #246/#249 — zScore + Day Δ + % vs baseline.
                let analyzed = scrubAnalyzedData.first {
                    Calendar.current.isDate($0.date, inSameDayAs: selected.date)
                }
                let deviationStr: String? = {
                    guard let a = analyzed else { return nil }
                    let d = a.percentDeviation * 100
                    let sign = d >= 0 ? "+" : ""
                    return "\(sign)\(String(format: "%.1f", d))% vs baseline"
                }()
                let zScoreStr: String? = {
                    guard let a = analyzed else { return nil }
                    let sign = a.zScore >= 0 ? "+" : ""
                    return "\(sign)\(String(format: "%.1f", a.zScore))σ"
                }()
                let dayDeltaStr: String? = {
                    guard let roc = analyzed?.rateOfChange else { return nil }
                    let s = roc >= 0 ? "+" : ""
                    return "Day Δ \(s)\(String(format: "%.0f", roc * 100))%"
                }()
                ChartTooltip(
                    date: selected.date,
                    value: valueText,
                    unit: depthTimelineUnit,
                    deviation: deviationStr,
                    isOutlier: analyzed?.isOutlier ?? false,
                    zScore: zScoreStr,
                    dayDelta: dayDeltaStr
                )
                .accessibilityIdentifier(SurfaceID.trendsChartSelection)
                .accessibilityLabel(
                    ChartScrubSelection.enrichedCalloutText(
                        date: selected.date,
                        value: valueText,
                        unit: depthTimelineUnit,
                        deviation: deviationStr,
                        zScore: zScoreStr,
                        dayDelta: dayDeltaStr
                    )
                )
                .position(
                    x: min(max(xPos, 80), geometry.size.width - 80),
                    y: max(yPos - 70, 50)
                )
            }
        }
    }
    
    private func scrubOverlay(proxy: ChartProxy) -> some View {
        GeometryReader { geo in
            Rectangle()
                .fill(Color.clear)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            selectNearestScrub(at: value.location, proxy: proxy, geo: geo)
                        }
                        .onEnded { _ in
                            selectedScrubDay = nil
                            lastHapticID = nil
                        }
                )
        }
    }
    
    private func selectNearestScrub(at location: CGPoint, proxy: ChartProxy, geo: GeometryProxy) {
        let date: Date?
        if #available(iOS 17.0, *) {
            guard let plotFrame = proxy.plotFrame else { return }
            let x = location.x - geo[plotFrame].origin.x
            date = proxy.value(atX: x)
        } else {
            let width = geo.size.width
            guard width > 0,
                  let first = filteredHistory.first?.date,
                  let last = filteredHistory.last?.date else { return }
            date = ChartScrubSelection.date(
                atFraction: location.x / width,
                from: first,
                to: last
            )
        }
        guard let date,
              let idx = ChartScrubSelection.nearestIndex(
                in: filteredHistory.map(\.date),
                to: date
              ) else { return }
        let point = filteredHistory[idx]
        selectedScrubDay = point
        if point.id != lastHapticID {
            lastHapticID = point.id
            if !reduceMotion {
                Haptic.selectionChanged()
            }
        }
    }
    
    // MARK: - Depth Timeline
    private var primaryDepthMetric: MetricToggle {
        // Prefer readiness when selected; otherwise first selected toggle.
        if selectedMetrics.contains(.readiness) { return .readiness }
        return MetricToggle.allCases.first { selectedMetrics.contains($0) } ?? .readiness
    }

    private var depthTimelinePoints: [(date: Date, value: Double)] {
        switch primaryDepthMetric {
        case .readiness:
            return filteredHistory.map { ($0.date, Double(readinessScores[$0.id] ?? 0)) }
        case .sleep:
            return filteredHistory.map { ($0.date, $0.sleepHours) }
        case .hrv:
            return filteredHistory.map { ($0.date, Double($0.hrv)) }
        case .rhr:
            return filteredHistory.map { ($0.date, Double($0.restingHeartRate)) }
        case .calories:
            return filteredHistory.map { ($0.date, $0.activeCalories) }
        }
    }

    private var depthTimelineUnit: String {
        switch primaryDepthMetric {
        case .readiness: return "%"
        case .sleep: return "h"
        case .hrv: return "ms"
        case .rhr: return "bpm"
        case .calories: return "kcal"
        }
    }

    private var depthTimelineSection: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 12) {
                // Honest #258/#259: Baseline Bands + Volatility strip toggles.
                HStack(spacing: 8) {
                    ToggleChip(label: "Baseline Bands", isOn: $showBaselineBands)
                        .accessibilityIdentifier(SurfaceID.trendsBaselineBandsToggle)
                    ToggleChip(label: "Volatility", isOn: $showVolatility)
                        .accessibilityIdentifier(SurfaceID.trendsVolatilityToggle)
                    ToggleChip(label: "Momentum", isOn: $showMomentum)
                        .accessibilityIdentifier(SurfaceID.trendsMomentumToggle)
                    ToggleChip(label: "Day Δ", isOn: $showRateOfChange)
                        .accessibilityIdentifier(SurfaceID.trendsDayDeltaToggle)
                    Spacer(minLength: 0)
                }

                DepthTimelineChart(
                    title: "\(primaryDepthMetric.rawValue) Depth Timeline",
                    unit: depthTimelineUnit,
                    color: primaryDepthMetric.color,
                    points: depthTimelinePoints,
                    period: selectedPeriod,
                    showBaselineBands: showBaselineBands
                )

                if showBaselineBands {
                    HStack(spacing: 6) {
                        Capsule()
                            .stroke(RTColor.tertiaryText, style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                            .frame(width: 18, height: 2)
                        Text("Baseline")
                            .font(.caption2)
                            .foregroundStyle(RTColor.secondaryText)
                            .accessibilityIdentifier(SurfaceID.trendsBaselineBands)
                        Text("±2σ")
                            .font(.caption2)
                            .foregroundStyle(RTColor.tertiaryText)
                        Spacer(minLength: 0)
                    }
                    .accessibilityLabel("Baseline bands plus or minus two sigma")
                }

                // Honest #259: elevate unused AnalyzedDataPoint.volatility / rollingVolatility.
                if showVolatility {
                    trendsVolatilityStrip
                }
                // Honest #260: elevate unused AnalyzedDataPoint.momentum.
                if showMomentum {
                    trendsMomentumStrip
                }
                // Honest #261: elevate unused AnalyzedDataPoint.rateOfChange (Day Δ).
                if showRateOfChange {
                    trendsDayDeltaStrip
                }
            }
        }
    }

    // MARK: - Metric Cards
    private var metricCards: some View {
        VStack(spacing: AppleTheme.cardPadding) {
            AppSectionHeader(title: "Metric Stats")
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                if selectedMetrics.contains(.readiness) {
                    let scores = filteredHistory.map { readinessScores[$0.id] ?? 0 }
                    TrendStatCard(
                        icon: "gauge.with.dots.needle.67percent",
                        label: "Readiness",
                        color: RTColor.optimal,
                        current: Double(scores.last ?? 0),
                        avg: scores.isEmpty ? 0 : Double(scores.reduce(0, +)) / Double(scores.count),
                        best: Double(scores.max() ?? 0),
                        unit: ""
                    )
                }
                
                if selectedMetrics.contains(.sleep) {
                    TrendStatCard(
                        icon: "bed.double.fill",
                        label: "Sleep",
                        color: RTColor.sleep,
                        current: filteredHistory.last?.sleepHours ?? 0,
                        avg: filteredHistory.isEmpty ? 0 : filteredHistory.map { $0.sleepHours }.reduce(0, +) / Double(filteredHistory.count),
                        best: filteredHistory.map { $0.sleepHours }.max() ?? 0,
                        unit: "h"
                    )
                }
                
                if selectedMetrics.contains(.hrv) {
                    TrendStatCard(
                        icon: "waveform.path.ecg",
                        label: "HRV",
                        color: RTColor.hrv,
                        current: Double(filteredHistory.last?.hrv ?? 0),
                        avg: filteredHistory.isEmpty ? 0 : Double(filteredHistory.map { $0.hrv }.reduce(0, +)) / Double(filteredHistory.count),
                        best: Double(filteredHistory.map { $0.hrv }.max() ?? 0),
                        unit: "ms"
                    )
                }
                
                if selectedMetrics.contains(.rhr) {
                    TrendStatCard(
                        icon: "heart.fill",
                        label: "Resting HR",
                        color: RTColor.strain,
                        current: Double(filteredHistory.last?.restingHeartRate ?? 0),
                        avg: filteredHistory.isEmpty ? 0 : Double(filteredHistory.map { $0.restingHeartRate }.reduce(0, +)) / Double(filteredHistory.count),
                        best: Double(filteredHistory.map { $0.restingHeartRate }.min() ?? 0),
                        unit: "bpm"
                    )
                }
                
                if selectedMetrics.contains(.calories) {
                    TrendStatCard(
                        icon: "flame.fill",
                        label: "Active Cals",
                        color: RTColor.caution,
                        current: Double(filteredHistory.last?.activeCalories ?? 0),
                        avg: filteredHistory.isEmpty ? 0 : filteredHistory.map { $0.activeCalories }.reduce(0, +) / Double(filteredHistory.count),
                        best: filteredHistory.map { $0.activeCalories }.max() ?? 0,
                        unit: "cal"
                    )
                }
            }
        }
    }
    
    // MARK: - Correlation Section
    private var correlationSection: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Sleep vs Recovery")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(RTColor.primaryText)
                
                Chart(filteredHistory) { day in
                    PointMark(
                        x: .value("Sleep", day.sleepHours),
                        y: .value("Readiness", readinessScores[day.id] ?? 0)
                    )
                    .foregroundStyle(RTColor.optimal.opacity(0.7))
                    .symbolSize(60)
                    
                    // Trend line approximation
                    let avgReadiness = filteredHistory.map { readinessScores[$0.id] ?? 0 }.reduce(0, +) / filteredHistory.count
                    RuleMark(y: .value("Avg", avgReadiness))
                        .foregroundStyle(RTColor.primaryText.opacity(0.12))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                }
                .frame(height: 200)
                
                HStack {
                    Text("Sleep (hours)")
                        .font(.caption2)
                        .foregroundStyle(RTColor.secondaryText)
                    Spacer()
                }
            }
        }
    }
}

// MARK: - Trend Stat Card
private struct TrendStatCard: View {
    let icon: String
    let label: String
    let color: Color
    let current: Double
    let avg: Double
    let best: Double
    let unit: String
    
    var body: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    // Honest #84: Apple circular tint well on Trend Detail summary cards.
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
                    Text(formatted(current))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(RTColor.primaryText)
                    Text(unit)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(RTColor.secondaryText)
                }
                
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Avg")
                            .font(.caption2)
                            .foregroundStyle(RTColor.tertiaryText)
                        Text(formatted(avg))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(RTColor.primaryText)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Best")
                            .font(.caption2)
                            .foregroundStyle(RTColor.tertiaryText)
                        Text(formatted(best))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(color)
                    }
                }
            }
            .padding(12)
        }
    }
    
    private func formatted(_ value: Double) -> String {
        if value == floor(value) {
            return "\(Int(value))"
        }
        return String(format: "%.1f", value)
    }
}

// MARK: - Trend Period Label
extension TrendPeriod {
    var detailLabel: String {
        switch self {
        case .week: return "7D"
        case .month: return "30D"
        case .quarter: return "90D"
        case .year: return "1Y"
        }
    }
}
