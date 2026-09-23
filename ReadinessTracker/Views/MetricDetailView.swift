import SwiftUI
import Charts

struct MetricDetailView: View {
    let metric: MetricType
    let currentValue: Double
    let history: [DailyHealthData]
    let source: DataSource

    @State private var selectedPeriod: TrendPeriod = .week
    @State private var selectedDataPoint: DailyHealthData?
    @State private var lastHapticID: DailyHealthData.ID?
    /// Honest #247–#251: classic parity with Advanced overlays / strips / bands / outliers.
    @State private var showMA14 = true
    @State private var showEMA = true
    @State private var showVolatility = true
    @State private var showMomentum = true
    @State private var showRateOfChange = true
    @State private var showBaselineBands = true
    @State private var showOutliers = true
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var filteredHistory: [DailyHealthData] {
        let days = selectedPeriod.rawValue
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        return history
            .filter { $0.date >= cutoff }
            .sorted { $0.date < $1.date }
    }

    var values: [(date: Date, value: Double)] {
        filteredHistory.map { ($0.date, metricValue(for: $0)) }
    }

    /// Elevates unused `AnalyzedDataPoint` series on classic MetricDetailView.
    var analyzedData: [AnalyzedDataPoint] {
        TrendAnalysisEngine.analyze(history: values, metric: metric)
    }

    var baseline: Double {
        let vals = values.map { $0.value }
        guard vals.count > 1 else { return currentValue }
        return vals.reduce(0, +) / Double(vals.count)
    }

    /// Matches AdvancedMetricDetailView — used for ±2σ baseline bands.
    var analysisStdDev: Double {
        TrendAnalysisEngine.standardDeviation(values: values.map(\.value))
    }

    /// Honest #253: mirror Advanced — elevate unused classifyTrend on classic.
    var trendClassification: TrendAnalysisEngine.TrendStrength? {
        guard let analysis = analyzedData.last,
              let slope = analysis.trendSlope,
              let r2 = analysis.trendRSquared else { return nil }
        return TrendAnalysisEngine.classifyTrend(slope: slope, rSquared: r2, metric: metric)
    }

    var trend: TrendDirection {
        guard values.count >= 2 else { return .flat }
        let recent = values.suffix(3).map { $0.value }.reduce(0, +) / Double(min(3, values.count))
        let threshold = baseline * 0.03
        if abs(recent - baseline) < threshold { return .flat }
        // Trend direction tracks the raw value direction; trendLabel/trendColor
        // handle the higherIsBetter inversion when labeling.
        return recent > baseline ? .up : .down
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: RTLayout.sectionSpacing) {
                // Hero value
                heroSection
                    .slideIn(delay: 0)

                // Period selector
                periodSelector
                    .slideIn(delay: 0.05)

                // Main trend chart
                trendChart
                    .slideIn(delay: 0.1)

                // Honest #251: OutlierCallout list (Advanced Highlights parity)
                classicOutlierSection
                    .slideIn(delay: 0.11)

                // Depth timeline (baseline band + MA7)
                depthTimelineSection
                    .slideIn(delay: 0.12)

                // Stats grid
                statsSection
                    .slideIn(delay: 0.15)

                // Honest #252: Distribution histogram (Advanced parity, ≥5 days)
                if values.count >= 5 {
                    DistributionHistogramView(
                        history: values,
                        metric: metric
                    )
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier(SurfaceID.metricClassicHistogram)
                    .slideIn(delay: 0.17)
                }

                // Smart Insights
                if values.count >= 3 {
                    SmartInsightsView(
                        metric: metric,
                        history: values,
                        currentValue: currentValue
                    )
                    .slideIn(delay: 0.2)
                }

                // Recovery Trajectory — post high-strain days (Honest #238)
                if filteredHistory.count >= 5 {
                    RecoveryTrajectoryView(
                        history: values,
                        strainHistory: filteredHistory.map { ($0.date, $0.activeCalories) },
                        metric: metric
                    )
                    .slideIn(delay: 0.25)
                }

                // Weekly Pattern
                if values.count >= 7 {
                    WeeklyPatternView(
                        history: values,
                        metric: metric
                    )
                    .slideIn(delay: 0.3)
                }

                // Metric Correlation (HRV vs Sleep for sleep metric, etc)
                if filteredHistory.count >= 3 {
                    let correlationPair = correlationMetrics()
                    MetricCorrelationView(
                        history: filteredHistory,
                        xMetric: correlationPair.x,
                        yMetric: correlationPair.y
                    )
                    .slideIn(delay: 0.35)
                }

                // Why no old data explanation
                if source == .appleWatch {
                    healthKitInfoSection
                        .slideIn(delay: 0.4)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(AppBackground())
        .accessibilityIdentifier(SurfaceID.metricDetail)
        .navigationTitle(metric.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(RTColor.background, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
    }

    // MARK: - Hero Section
    private var heroSection: some View {
        NativeCard {
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    // Honest #80: Apple circular tint well on Metric Detail hero.
                    Image(systemName: metric.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(metric.color)
                        .frame(width: 44, height: 44)
                        .background(metric.color.opacity(0.14))
                        .clipShape(Circle())
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(metric.title)
                            .font(RTFont.caption)
                            .foregroundColor(RTColor.secondaryText)

                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Text(formattedValue(currentValue))
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundColor(RTColor.primaryText)

                            Text(metric.unit)
                                .font(RTFont.headline)
                                .foregroundColor(RTColor.secondaryText)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        TrendArrow(direction: trend, color: metric.color)
                            .font(.system(size: 20))

                        Text(trendLabel)
                            .font(RTFont.captionSmall)
                            .foregroundColor(trendColor)
                    }
                }

                // Honest #253: elevate classifyTrend on classic (parity with Advanced).
                if let strength = trendClassification {
                    classicClassifyTrendCallout(strength)
                }

                // Zone indicator
                if let zone = metric.zone(for: currentValue) {
                    HStack(spacing: 8) {
                        Text(zone.label)
                            .font(RTFont.caption)
                            .foregroundColor(zone.color)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(zone.color.opacity(0.15))
                            .cornerRadius(8)

                        Text(zone.description)
                            .font(RTFont.captionSmall)
                            .foregroundColor(RTColor.secondaryText)

                        Spacer()
                    }
                }
            }
        }
    }

    // MARK: - Period Selector
    private var periodSelector: some View {
        AppSegmentedControl(options: TrendPeriod.allCases, selection: $selectedPeriod) { $0.label }
            .onChange(of: selectedPeriod) { _ in Haptic.selectionChanged() }
    }

    // MARK: - Depth Timeline
    private var depthTimelineSection: some View {
        NativeCard {
            DepthTimelineChart(
                title: "\(metric.title) Depth Timeline",
                unit: metric.unit,
                color: metric.color,
                points: values,
                period: selectedPeriod
            )
        }
    }

    // MARK: - Trend Chart
    private var trendChart: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Trend")
                        .font(RTFont.headline)
                        .foregroundColor(RTColor.primaryText)

                    Spacer()

                    if selectedDataPoint == nil {
                        Text("Drag to inspect")
                            .font(RTFont.captionSmall)
                            .foregroundColor(RTColor.tertiaryText)
                    }
                }

                // Honest #247: Advanced overlay subset on classic MetricDetailView.
                classicOverlayToggles

                if showEMA {
                    Text("EMA responds faster than SMA to recent change")
                        .font(.caption2)
                        .foregroundStyle(RTColor.secondaryText)
                        .accessibilityIdentifier(SurfaceID.metricClassicEMA)
                }
                if showMA14 {
                    Text("MA14 smooths longer trends than MA7")
                        .font(.caption2)
                        .foregroundStyle(RTColor.secondaryText)
                        .accessibilityIdentifier(SurfaceID.metricClassicMA14)
                }

                // Honest #248: Advanced strip stack on classic MetricDetailView.
                classicStripStack

                if values.count >= 2 {
                    Chart {
                        if showBaselineBands {
                            classicBaselineBandMarks
                        }

                        ForEach(filteredHistory) { point in
                            LineMark(
                                x: .value("Date", point.date, unit: .day),
                                y: .value("Value", metricValue(for: point))
                            )
                            .foregroundStyle(metric.color)
                            .interpolationMethod(.catmullRom)
                            .lineStyle(StrokeStyle(lineWidth: 2.5))

                            AreaMark(
                                x: .value("Date", point.date, unit: .day),
                                y: .value("Value", metricValue(for: point))
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [metric.color.opacity(0.2), metric.color.opacity(0.0)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .interpolationMethod(.catmullRom)

                            PointMark(
                                x: .value("Date", point.date, unit: .day),
                                y: .value("Value", metricValue(for: point))
                            )
                            .foregroundStyle(classicPointColor(for: point))
                            .symbolSize(classicPointSize(for: point))
                        }

                        if showMA14 {
                            classicMA14Marks
                        }
                        if showEMA {
                            classicEMAMarks
                        }
                        if showOutliers {
                            classicOutlierMarks
                        }
                        if showBaselineBands {
                            classicBaselineRule
                        }

                        if let selected = selectedDataPoint {
                            RuleMark(x: .value("Selected", selected.date))
                                .foregroundStyle(RTColor.primaryText.opacity(0.35))
                                .lineStyle(StrokeStyle(lineWidth: 1))

                            PointMark(
                                x: .value("Selected", selected.date, unit: .day),
                                y: .value("Value", metricValue(for: selected))
                            )
                            .foregroundStyle(metric.color)
                            .symbolSize(120)
                        }
                    }
                    .frame(height: 220)
                    .chartYScale(domain: chartDomain)
                    .chartXAxis {
                        AxisMarks(values: .stride(by: selectedPeriod == .week ? .day : .weekOfYear)) { value in
                            AxisGridLine()
                            AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                        }
                    }
                    .chartBackground { proxy in
                        classicAnnotationOverlay(proxy: proxy)
                    }
                    .chartOverlay { proxy in
                        classicScrubOverlay(proxy: proxy)
                    }
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier(SurfaceID.metricChartScrub)

                    classicOverlayLegend
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 40))
                            .foregroundColor(RTColor.surfaceHighlight)

                        Text("Not enough data")
                            .font(RTFont.body)
                            .foregroundColor(RTColor.secondaryText)

                        Text("Need at least 2 data points to show trends")
                            .font(RTFont.captionSmall)
                            .foregroundColor(RTColor.tertiaryText)
                    }
                    .frame(height: 220)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .accessibilityIdentifier(SurfaceID.metricDetail)
    }

    private var classicOverlayToggles: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ToggleChip(label: "Baseline Bands", isOn: $showBaselineBands)
                    .accessibilityIdentifier(SurfaceID.metricClassicBaselineBandsToggle)
                ToggleChip(label: "Outliers", isOn: $showOutliers)
                    .accessibilityIdentifier(SurfaceID.metricClassicOutliersToggle)
                ToggleChip(label: "MA14", isOn: $showMA14)
                    .accessibilityIdentifier(SurfaceID.metricClassicMA14Toggle)
                ToggleChip(label: "EMA", isOn: $showEMA)
                    .accessibilityIdentifier(SurfaceID.metricClassicEMAToggle)
                ToggleChip(label: "Volatility", isOn: $showVolatility)
                    .accessibilityIdentifier(SurfaceID.metricClassicVolatilityToggle)
                ToggleChip(label: "Momentum", isOn: $showMomentum)
                    .accessibilityIdentifier(SurfaceID.metricClassicMomentumToggle)
                ToggleChip(label: "Day Δ", isOn: $showRateOfChange)
                    .accessibilityIdentifier(SurfaceID.metricClassicROCToggle)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(SurfaceID.metricClassicOverlays)
    }

    @ViewBuilder
    private var classicStripStack: some View {
        VStack(alignment: .leading, spacing: 12) {
            if showVolatility { classicVolatilityStrip }
            if showMomentum { classicMomentumStrip }
            if showRateOfChange { classicRateOfChangeStrip }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(SurfaceID.metricClassicStrips)
    }

    @ChartContentBuilder
    private var classicMA14Marks: some ChartContent {
        ForEach(analyzedData) { point in
            if let ma = point.movingAverage14 {
                LineMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value("MA14", ma)
                )
                .foregroundStyle(RTColor.recovery.opacity(0.9))
                .lineStyle(StrokeStyle(lineWidth: 1.75, dash: [8, 4]))
                .interpolationMethod(.catmullRom)
            }
        }
    }

    @ChartContentBuilder
    private var classicEMAMarks: some ChartContent {
        ForEach(analyzedData) { point in
            if let ema = point.ema7 {
                LineMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value("EMA7", ema)
                )
                .foregroundStyle(RTColor.hrv.opacity(0.85))
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [6, 3]))
                .interpolationMethod(.catmullRom)
            }
        }
    }

    private var classicOverlayLegend: some View {
        HStack(spacing: 16) {
            if showMA14 {
                HStack(spacing: 6) {
                    Capsule()
                        .stroke(RTColor.recovery.opacity(0.9), style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                        .frame(width: 18, height: 2)
                    Text("MA14")
                        .font(.caption2)
                        .foregroundStyle(RTColor.secondaryText)
                }
            }
            if showEMA {
                HStack(spacing: 6) {
                    Capsule()
                        .stroke(RTColor.hrv.opacity(0.85), style: StrokeStyle(lineWidth: 2, dash: [6, 3]))
                        .frame(width: 18, height: 2)
                    Text("EMA")
                        .font(.caption2)
                        .foregroundStyle(RTColor.secondaryText)
                }
            }
            if showBaselineBands {
                HStack(spacing: 6) {
                    Capsule()
                        .stroke(RTColor.tertiaryText, style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                        .frame(width: 18, height: 2)
                    Text("Baseline")
                        .font(.caption2)
                        .foregroundStyle(RTColor.secondaryText)
                        .accessibilityIdentifier(SurfaceID.metricClassicBaselineBands)
                }
            }
            if showOutliers {
                HStack(spacing: 4) {
                    Circle()
                        .fill(.red.opacity(0.3))
                        .frame(width: 8, height: 8)
                    Text("Outlier")
                        .font(.caption2)
                        .foregroundStyle(RTColor.secondaryText)
                        .accessibilityIdentifier(SurfaceID.metricClassicOutliers)
                }
            }
            Spacer(minLength: 0)
        }
    }

    // MARK: - Classic baseline bands + outliers (Honest #251)

    @ChartContentBuilder
    private var classicBaselineBandMarks: some ChartContent {
        let cal = Calendar.current
        let low = baseline - 2 * analysisStdDev
        let high = baseline + 2 * analysisStdDev
        ForEach(analyzedData) { point in
            let endDate = cal.date(byAdding: .day, value: 1, to: point.date) ?? point.date
            let color = classicBandColor(zScore: point.zScore).opacity(0.08)
            RectangleMark(
                xStart: .value("Date", point.date),
                xEnd: .value("Date", endDate),
                yStart: .value("Low", low),
                yEnd: .value("High", high)
            )
            .foregroundStyle(color)
        }
    }

    @ChartContentBuilder
    private var classicOutlierMarks: some ChartContent {
        ForEach(analyzedData.filter(\.isOutlier)) { point in
            PointMark(
                x: .value("Date", point.date, unit: .day),
                y: .value("Value", point.rawValue)
            )
            .foregroundStyle(.red.opacity(0.3))
            .symbolSize(200)
        }
    }

    @ChartContentBuilder
    private var classicBaselineRule: some ChartContent {
        RuleMark(y: .value("Baseline", baseline))
            .foregroundStyle(RTColor.primaryText.opacity(0.2))
            .lineStyle(StrokeStyle(lineWidth: 1, dash: [6, 4]))
    }

    private func classicBandColor(zScore: Double) -> Color {
        let absZ = abs(zScore)
        if absZ > 2 { return .red }
        if absZ > 1 { return .orange }
        return .green
    }

    private func classicPointIsOutlier(_ point: DailyHealthData) -> Bool {
        guard showOutliers else { return false }
        return analyzedData.first {
            Calendar.current.isDate($0.date, inSameDayAs: point.date)
        }?.isOutlier ?? false
    }

    private func classicPointColor(for point: DailyHealthData) -> Color {
        if classicPointIsOutlier(point) { return .red }
        return point.date.isToday ? metric.color : metric.color.opacity(0.5)
    }

    private func classicPointSize(for point: DailyHealthData) -> CGFloat {
        if classicPointIsOutlier(point) { return 120 }
        return point.date.isToday ? 80 : 40
    }

    @ViewBuilder
    private var classicOutlierSection: some View {
        let outliers = analyzedData.filter(\.isOutlier)
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
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(SurfaceID.metricClassicOutlierList)
            .accessibilityLabel("Outlier highlights")
        }
    }

    // MARK: - Classic strips (Honest #248) — Advanced #240–#243 parity

    private var volatilityPoints: [(date: Date, cv: Double)] {
        analyzedData.compactMap { point in
            guard let cv = point.volatility else { return nil }
            return (point.date, cv)
        }
    }

    private var latestVolatilityBand: (label: String, color: Color) {
        guard let cv = volatilityPoints.last?.cv else {
            return ("—", RTColor.secondaryText)
        }
        if cv >= 0.15 { return ("High", RTColor.warning) }
        if cv >= 0.08 { return ("Mild", RTColor.caution) }
        return ("Low", RTColor.optimal)
    }

    private var volatilityYDomain: ClosedRange<Double> {
        let vals = volatilityPoints.map(\.cv)
        let hi = max(vals.max() ?? 0.2, 0.2)
        return 0...(hi * 1.15)
    }

    private var classicVolatilityStrip: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("7-Day Volatility")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
                Spacer()
                if let cv = volatilityPoints.last?.cv {
                    Text(String(format: "CV %.0f%% · %@", cv * 100, latestVolatilityBand.label))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(latestVolatilityBand.color)
                        .monospacedDigit()
                }
            }

            if !volatilityPoints.isEmpty {
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
                        yEnd: .value("HighTop", volatilityYDomain.upperBound)
                    )
                    .foregroundStyle(RTColor.warning.opacity(0.08))

                    ForEach(Array(volatilityPoints.enumerated()), id: \.offset) { _, point in
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
                .chartYScale(domain: volatilityYDomain)
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
        .accessibilityIdentifier(SurfaceID.metricClassicVolatility)
        .accessibilityLabel("Seven day rolling volatility")
    }

    private var momentumPoints: [(date: Date, mom: Double)] {
        analyzedData.compactMap { point in
            guard let mom = point.momentum else { return nil }
            return (point.date, mom)
        }
    }

    private var latestMomentumBand: (label: String, color: Color) {
        guard let mom = momentumPoints.last?.mom else {
            return ("—", RTColor.secondaryText)
        }
        let improving: Bool
        if metric.higherIsBetter {
            improving = mom > 0
        } else {
            improving = mom < 0
        }
        if abs(mom) < 0.05 { return ("Flat", RTColor.secondaryText) }
        if improving { return ("Rising", RTColor.optimal) }
        return ("Fading", RTColor.warning)
    }

    private var momentumYDomain: ClosedRange<Double> {
        let vals = momentumPoints.map(\.mom)
        let lo = min(vals.min() ?? -0.2, -0.2)
        let hi = max(vals.max() ?? 0.2, 0.2)
        let pad = max((hi - lo) * 0.1, 0.05)
        return (lo - pad)...(hi + pad)
    }

    private var classicMomentumStrip: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("7-Day Momentum")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
                Spacer()
                if let mom = momentumPoints.last?.mom {
                    let sign = mom >= 0 ? "+" : ""
                    Text(String(format: "%@%.0f%% · %@", sign, mom * 100, latestMomentumBand.label))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(latestMomentumBand.color)
                        .monospacedDigit()
                }
            }

            if !momentumPoints.isEmpty {
                Chart {
                    RuleMark(y: .value("Zero", 0))
                        .foregroundStyle(RTColor.tertiaryText.opacity(0.6))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))

                    ForEach(Array(momentumPoints.enumerated()), id: \.offset) { _, point in
                        AreaMark(
                            x: .value("Date", point.date, unit: .day),
                            yStart: .value("Zero", 0),
                            yEnd: .value("Mom", point.mom)
                        )
                        .foregroundStyle(
                            (metric.higherIsBetter ? point.mom >= 0 : point.mom <= 0)
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
                .chartYScale(domain: momentumYDomain)
                .chartXAxis(.hidden)
                .chartYAxis {
                    AxisMarks(position: .leading, values: [momentumYDomain.lowerBound, 0, momentumYDomain.upperBound]) { value in
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
        .accessibilityIdentifier(SurfaceID.metricClassicMomentum)
        .accessibilityLabel("Seven day momentum")
    }

    private var rocPoints: [(date: Date, roc: Double)] {
        analyzedData.compactMap { point in
            guard let roc = point.rateOfChange else { return nil }
            return (point.date, roc)
        }
    }

    private var latestROCBand: (label: String, color: Color) {
        guard let roc = rocPoints.last?.roc else {
            return ("—", RTColor.secondaryText)
        }
        let improving: Bool
        if metric.higherIsBetter {
            improving = roc > 0
        } else {
            improving = roc < 0
        }
        if abs(roc) < 0.03 { return ("Flat", RTColor.secondaryText) }
        if improving { return ("Up", RTColor.optimal) }
        return ("Down", RTColor.warning)
    }

    private var rocYDomain: ClosedRange<Double> {
        let vals = rocPoints.map(\.roc)
        let lo = min(vals.min() ?? -0.25, -0.25)
        let hi = max(vals.max() ?? 0.25, 0.25)
        let pad = max((hi - lo) * 0.1, 0.05)
        return (lo - pad)...(hi + pad)
    }

    private var classicRateOfChangeStrip: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Day-over-Day Change")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
                Spacer()
                if let roc = rocPoints.last?.roc {
                    let sign = roc >= 0 ? "+" : ""
                    Text(String(format: "%@%.0f%% · %@", sign, roc * 100, latestROCBand.label))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(latestROCBand.color)
                        .monospacedDigit()
                }
            }

            if !rocPoints.isEmpty {
                Chart {
                    RuleMark(y: .value("Zero", 0))
                        .foregroundStyle(RTColor.tertiaryText.opacity(0.6))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))

                    ForEach(Array(rocPoints.enumerated()), id: \.offset) { _, point in
                        BarMark(
                            x: .value("Date", point.date, unit: .day),
                            y: .value("ROC", point.roc)
                        )
                        .foregroundStyle(
                            (metric.higherIsBetter ? point.roc >= 0 : point.roc <= 0)
                                ? RTColor.optimal.opacity(0.75)
                                : RTColor.warning.opacity(0.75)
                        )
                        .cornerRadius(2)
                    }
                }
                .frame(height: 72)
                .chartYScale(domain: rocYDomain)
                .chartXAxis(.hidden)
                .chartYAxis {
                    AxisMarks(position: .leading, values: [rocYDomain.lowerBound, 0, rocYDomain.upperBound]) { value in
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
        .accessibilityIdentifier(SurfaceID.metricClassicROC)
        .accessibilityLabel("Day over day rate of change")
    }

    private func classicAnnotationOverlay(proxy: ChartProxy) -> some View {
        GeometryReader { geometry in
            if let selected = selectedDataPoint {
                let xPos = proxy.position(forX: selected.date) ?? 0
                let yPos = proxy.position(forY: metricValue(for: selected)) ?? 0
                let valueText = formattedValue(metricValue(for: selected))
                // Honest #249: mirror Advanced #246 — elevate AnalyzedDataPoint zScore + Day Δ.
                let analyzed = analyzedData.first {
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
                    unit: metric.unit,
                    deviation: deviationStr,
                    isOutlier: analyzed?.isOutlier ?? false,
                    zScore: zScoreStr,
                    dayDelta: dayDeltaStr
                )
                .accessibilityIdentifier(SurfaceID.metricClassicSelection)
                .accessibilityLabel(
                    ChartScrubSelection.enrichedCalloutText(
                        date: selected.date,
                        value: valueText,
                        unit: metric.unit,
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

    /// Drag scrub (Apple Health / WHOOP). Parity with AdvancedMetricChartView.
    private func classicScrubOverlay(proxy: ChartProxy) -> some View {
        GeometryReader { geo in
            Rectangle()
                .fill(Color.clear)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            selectNearestClassic(at: value.location, proxy: proxy, geo: geo)
                        }
                        .onEnded { _ in
                            selectedDataPoint = nil
                            lastHapticID = nil
                        }
                )
        }
    }

    private func selectNearestClassic(at location: CGPoint, proxy: ChartProxy, geo: GeometryProxy) {
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
        selectedDataPoint = point
        if point.id != lastHapticID {
            lastHapticID = point.id
            if !reduceMotion {
                Haptic.selectionChanged()
            }
        }
    }

    private var chartDomain: ClosedRange<Double> {
        let vals = values.map { $0.value }
        guard let min = vals.min(), let max = vals.max() else {
            return 0...100
        }
        let padding = (max - min) * 0.15
        return (min - padding)...(max + padding)
    }

    // MARK: - Stats Section
    private var statsSection: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Statistics")
                    .font(RTFont.headline)
                    .foregroundColor(RTColor.primaryText)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    StatItem(label: "Average", value: formattedValue(baseline), unit: metric.unit)
                    StatItem(label: "Best", value: formattedValue(values.map { $0.value }.max() ?? 0), unit: metric.unit)
                    StatItem(label: "Worst", value: formattedValue(values.map { $0.value }.min() ?? 0), unit: metric.unit)
                    StatItem(label: "Data Points", value: "\(values.count)", unit: "days")
                }
            }
        }
    }

    // MARK: - HealthKit Info Section
    private var healthKitInfoSection: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    // Honest #86: Apple circular tint well on Metric Detail About cue.
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(RTColor.caution)
                        .frame(width: 26, height: 26)
                        .background(RTColor.caution.opacity(0.14))
                        .clipShape(Circle())
                        .accessibilityHidden(true)

                    Text("Why can't I see older data?")
                        .font(RTFont.headline)
                        .foregroundColor(RTColor.primaryText)
                }

                Text("HealthKit only stores data from when you first granted permission. Apple does not retroactively backfill historical health data when you install a new app.")
                    .font(RTFont.body)
                    .foregroundColor(RTColor.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 8) {
                    InfoRow(icon: "checkmark.circle.fill", text: "Data from today forward is saved automatically")
                    InfoRow(icon: "checkmark.circle.fill", text: "Your data stays in Apple Health even if you delete this app")
                    InfoRow(icon: "xmark.circle.fill", text: "Past data before app install is not accessible via HealthKit")
                }

                Divider()
                    .background(RTColor.divider)

                Text("Tip: If you previously used another health app, that data may already exist in Apple Health and will appear here once you grant access.")
                    .font(RTFont.captionSmall)
                    .foregroundColor(RTColor.tertiaryText)
                    .italic()
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

    private func formattedValue(_ value: Double) -> String {
        switch metric {
        case .sleep:
            return String(format: "%.1f", value)
        case .hrv, .restingHR, .activeCalories, .bloodOxygen:
            return "\(Int(value))"
        }
    }

    private func classicClassifyTrendCallout(_ strength: TrendAnalysisEngine.TrendStrength) -> some View {
        let r2 = analyzedData.last?.trendRSquared
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
        .accessibilityIdentifier(SurfaceID.metricClassicTrendStrength)
        .accessibilityLabel("Trend strength \(strength.rawValue)")
    }

    private var trendLabel: String {
        switch trend {
        case .up: return metric.higherIsBetter ? "Improving" : "Worsening"
        case .down: return metric.higherIsBetter ? "Declining" : "Improving"
        case .flat: return "Stable"
        }
    }

    private var trendColor: Color {
        switch trend {
        case .up: return metric.higherIsBetter ? RTColor.optimal : RTColor.warning
        case .down: return metric.higherIsBetter ? RTColor.warning : RTColor.optimal
        case .flat: return RTColor.tertiaryText
        }
    }
}

// MARK: - Stat Item
struct StatItem: View {
    let label: String
    let value: String
    let unit: String

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(RTFont.captionSmall)
                .foregroundColor(RTColor.secondaryText)

            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(RTColor.primaryText)

                Text(unit)
                    .font(RTFont.captionSmall)
                    .foregroundColor(RTColor.tertiaryText)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(RTColor.surfaceElevated)
        )
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let icon: String
    let text: String

    private var tint: Color {
        icon.contains("xmark") ? RTColor.warning : RTColor.optimal
    }

    var body: some View {
        HStack(spacing: 8) {
            // Honest #100: Apple circular tint well on Metric About info bullets.
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 22, height: 22)
                .background(tint.opacity(0.14))
                .clipShape(Circle())
                .accessibilityHidden(true)

            Text(text)
                .font(RTFont.caption)
                .foregroundColor(RTColor.secondaryText)

            Spacer()
        }
    }
}

// MARK: - Date Extension
extension Date {
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
}

// MARK: - Metric Detail Helpers
extension MetricDetailView {
    private func correlationMetrics() -> (x: MetricType, y: MetricType) {
        switch metric {
        case .sleep:
            return (.sleep, .hrv)
        case .hrv:
            return (.hrv, .sleep)
        case .restingHR:
            return (.restingHR, .hrv)
        case .activeCalories:
            return (.activeCalories, .sleep)
        case .bloodOxygen:
            return (.bloodOxygen, .hrv)
        }
    }
}
