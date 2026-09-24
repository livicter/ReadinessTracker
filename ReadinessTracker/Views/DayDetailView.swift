import SwiftUI
import Charts

/// Full daily detail view — tapped from History row or any daily summary.
/// Shows every metric for that day with full charts and analysis.
struct DayDetailView: View {
    let data: DailyHealthData
    let history: [DailyHealthData]
    
    @Environment(\.dismiss) private var dismiss

    /// Honest #276: Trends #259 / classic #248 Volatility strip toggle (default on).
    @State private var showVolatility = true
    /// Honest #277: Trends #260 / classic #248 Momentum strip toggle (default on).
    @State private var showMomentum = true
    /// Honest #278: Trends #261 / classic #248 Day Δ strip toggle (default on).
    @State private var showRateOfChange = true

    /// Honest #291: HRV rollingVolatility strip toggle (Sleep #276 dual; default on).
    @State private var showHRVVolatility = true

    /// Honest #292: HRV momentum strip toggle (Sleep #277 dual; default on).
    @State private var showHRVMomentum = true

    /// Honest #293: HRV Day Δ strip toggle (Sleep #278 dual; default on).
    @State private var showHRVRateOfChange = true

    /// Honest #305: RHR rollingVolatility strip toggle (Sleep #276 / HRV #291 dual; default on).
    @State private var showRHRVolatility = true

    /// Honest #306: RHR momentum strip toggle (Sleep #277 / HRV #292 dual; default on).
    @State private var showRHRMomentum = true

    /// Honest #307: RHR Day Δ strip toggle (Sleep #278 / HRV #293 dual; default on).
    @State private var showRHRRateOfChange = true

    /// Honest #321: Strain rollingVolatility strip toggle (Sleep #276 / HRV #291 / RHR #305 dual; default on).
    @State private var showStrainVolatility = true

    /// Honest #322: Strain momentum strip toggle (Sleep #277 / HRV #292 / RHR #306 dual; default on).
    @State private var showStrainMomentum = true

    /// Honest #323: Strain Day Δ strip toggle (Sleep #278 / HRV #293 / RHR #307 dual; default on).
    @State private var showStrainRateOfChange = true
    
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


    /// Honest #326: SpO2 through day — optional bloodOxygen compactMap (GHealth leftover; SmartInsights entry).
    private var spo2SeriesThroughDay: [(date: Date, value: Double)] {
        history
            .filter { $0.date <= data.date }
            .sorted { $0.date < $1.date }
            .compactMap { day -> (date: Date, value: Double)? in
                guard let v = day.bloodOxygen, v > 0 else { return nil }
                return (day.date, v)
            }
    }

    /// Honest #282: HRV through day — DistributionHistogramView dual of Sleep #271.
    private var hrvSeriesThroughDay: [(date: Date, value: Double)] {
        history
            .filter { $0.date <= data.date }
            .sorted { $0.date < $1.date }
            .map { ($0.date, $0.hrv) }
    }


    /// Honest #296: RHR through day — SmartInsights / Histogram dual track entry.
    private var rhrSeriesThroughDay: [(date: Date, value: Double)] {
        history
            .filter { $0.date <= data.date }
            .sorted { $0.date < $1.date }
            .map { ($0.date, $0.restingHeartRate) }
    }


    /// Honest #298: analyze + classifyTrend on RHR through day (Sleep #274 / HRV #283 dual).
    private var rhrAnalyzedThroughDay: [AnalyzedDataPoint] {
        TrendAnalysisEngine.analyze(history: rhrSeriesThroughDay, metric: .restingHR)
    }

    private var rhrTrendClassification: TrendAnalysisEngine.TrendStrength? {
        guard let analysis = rhrAnalyzedThroughDay.last,
              let slope = analysis.trendSlope,
              let r2 = analysis.trendRSquared else { return nil }
        return TrendAnalysisEngine.classifyTrend(slope: slope, rSquared: r2, metric: .restingHR)
    }


    /// Honest #314: analyze + classifyTrend on Strain through day (Sleep #274 / HRV #283 / RHR #298 dual).
    private var strainAnalyzedThroughDay: [AnalyzedDataPoint] {
        TrendAnalysisEngine.analyze(history: strainSeriesThroughDay, metric: .activeCalories)
    }

    private var strainTrendClassification: TrendAnalysisEngine.TrendStrength? {
        guard let analysis = strainAnalyzedThroughDay.last,
              let slope = analysis.trendSlope,
              let r2 = analysis.trendRSquared else { return nil }
        return TrendAnalysisEngine.classifyTrend(slope: slope, rSquared: r2, metric: .activeCalories)
    }

    /// Honest #329: analyze + classifyTrend on SpO2 through day (Sleep #274 / Strain #314 dual).
    private var spo2AnalyzedThroughDay: [AnalyzedDataPoint] {
        TrendAnalysisEngine.analyze(history: spo2SeriesThroughDay, metric: .bloodOxygen)
    }

    private var spo2TrendClassification: TrendAnalysisEngine.TrendStrength? {
        guard let analysis = spo2AnalyzedThroughDay.last,
              let slope = analysis.trendSlope,
              let r2 = analysis.trendRSquared else { return nil }
        return TrendAnalysisEngine.classifyTrend(slope: slope, rSquared: r2, metric: .bloodOxygen)
    }

    /// Honest #330: % vs baseline for selected day's SpO2 (Sleep #280 / Strain #315 dual).
    private var spo2DayAnalyzed: AnalyzedDataPoint? {
        spo2AnalyzedThroughDay.first {
            Calendar.current.isDate($0.date, inSameDayAs: data.date)
        }
    }

    private var spo2PercentDeviationLabel: String? {
        guard let a = spo2DayAnalyzed else { return nil }
        let pct = a.percentDeviation * 100
        let sign = pct >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", pct))% vs baseline"
    }


    /// Honest #315: % vs baseline for selected day's Strain (Sleep #280 / HRV #284 / RHR #299 dual).
    private var strainDayAnalyzed: AnalyzedDataPoint? {
        strainAnalyzedThroughDay.first {
            Calendar.current.isDate($0.date, inSameDayAs: data.date)
        }
    }

    private var strainPercentDeviationLabel: String? {
        guard let a = strainDayAnalyzed else { return nil }
        let pct = a.percentDeviation * 100
        let sign = pct >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", pct))% vs baseline"
    }


    /// Honest #299: % vs baseline for selected day's RHR (Sleep #280 / HRV #284 dual).
    private var rhrDayAnalyzed: AnalyzedDataPoint? {
        rhrAnalyzedThroughDay.first {
            Calendar.current.isDate($0.date, inSameDayAs: data.date)
        }
    }

    private var rhrPercentDeviationLabel: String? {
        guard let a = rhrDayAnalyzed else { return nil }
        let pct = a.percentDeviation * 100
        let sign = pct >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", pct))% vs baseline"
    }

    /// Honest #283: analyze + classifyTrend on HRV through day (Sleep #274 dual).
    private var hrvAnalyzedThroughDay: [AnalyzedDataPoint] {
        TrendAnalysisEngine.analyze(history: hrvSeriesThroughDay, metric: .hrv)
    }

    private var hrvTrendClassification: TrendAnalysisEngine.TrendStrength? {
        guard let analysis = hrvAnalyzedThroughDay.last,
              let slope = analysis.trendSlope,
              let r2 = analysis.trendRSquared else { return nil }
        return TrendAnalysisEngine.classifyTrend(slope: slope, rSquared: r2, metric: .hrv)
    }

    /// Honest #284: % vs baseline for selected day's HRV (Sleep #280 dual).
    private var hrvDayAnalyzed: AnalyzedDataPoint? {
        hrvAnalyzedThroughDay.first {
            Calendar.current.isDate($0.date, inSameDayAs: data.date)
        }
    }

    private var hrvPercentDeviationLabel: String? {
        guard let a = hrvDayAnalyzed else { return nil }
        let pct = a.percentDeviation * 100
        let sign = pct >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", pct))% vs baseline"
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


    /// Honest #287: baseline ±2σ from HRV through day (Sleep #273 dual).
    private var hrvBaselineStats: (baseline: Double, stdDev: Double)? {
        let vals = hrvSeriesThroughDay.map(\.value)
        guard vals.count >= 5 else { return nil }
        let stdDev = TrendAnalysisEngine.standardDeviation(values: vals)
        guard stdDev > 0 else { return nil }
        return (TrendAnalysisEngine.mean(values: vals), stdDev)
    }


    /// Honest #302: baseline ±2σ from RHR through day (Sleep #273 / HRV #287 dual).
    private var rhrBaselineStats: (baseline: Double, stdDev: Double)? {
        let vals = rhrSeriesThroughDay.map(\.value)
        guard vals.count >= 5 else { return nil }
        let stdDev = TrendAnalysisEngine.standardDeviation(values: vals)
        guard stdDev > 0 else { return nil }
        return (TrendAnalysisEngine.mean(values: vals), stdDev)
    }


    /// Honest #318: baseline ±2σ from Strain through day (Sleep #273 / HRV #287 / RHR #302 dual).
    private var strainBaselineStats: (baseline: Double, stdDev: Double)? {
        let vals = strainSeriesThroughDay.map(\.value)
        guard vals.count >= 5 else { return nil }
        let stdDev = TrendAnalysisEngine.standardDeviation(values: vals)
        guard stdDev > 0 else { return nil }
        return (TrendAnalysisEngine.mean(values: vals), stdDev)
    }

    /// Honest #333: baseline ±2σ from SpO2 through day (Sleep #273 / Strain #318 dual).
    private var spo2BaselineStats: (baseline: Double, stdDev: Double)? {
        let vals = spo2SeriesThroughDay.map(\.value)
        guard vals.count >= 5 else { return nil }
        let stdDev = TrendAnalysisEngine.standardDeviation(values: vals)
        guard stdDev > 0 else { return nil }
        return (TrendAnalysisEngine.mean(values: vals), stdDev)
    }

    /// Honest #333: SpO2 points in seven-day window for Blood Oxygen Trend host.
    private var spo2SevenDayPoints: [(date: Date, value: Double, isSelected: Bool)] {
        sevenDayWindow.compactMap { day in
            guard let v = day.bloodOxygen, v > 0 else { return nil }
            return (day.date, v, day.id == data.id)
        }
    }

    /// Honest #274: classifyTrend on Sleep through day (classic #253 / Trends #255 parity).
    private var sleepTrendClassification: TrendAnalysisEngine.TrendStrength? {
        guard let analysis = sleepAnalyzedThroughDay.last,
              let slope = analysis.trendSlope,
              let r2 = analysis.trendRSquared else { return nil }
        return TrendAnalysisEngine.classifyTrend(slope: slope, rSquared: r2, metric: .sleep)
    }

    /// Honest #275: Sleep CV% through day (classic #254 / Trends #256 parity).
    private var sleepCoefficientOfVariation: Double? {
        let vals = sleepSeriesThroughDay.map(\.value)
        guard vals.count >= 2 else { return nil }
        return TrendAnalysisEngine.coefficientOfVariation(values: vals)
    }


    /// Honest #285: HRV CV% through day (Sleep #275 dual).
    private var hrvCoefficientOfVariation: Double? {
        let vals = hrvSeriesThroughDay.map(\.value)
        guard vals.count >= 2 else { return nil }
        return TrendAnalysisEngine.coefficientOfVariation(values: vals)
    }


    /// Honest #300: RHR CV% through day (Sleep #275 / HRV #285 dual).
    private var rhrCoefficientOfVariation: Double? {
        let vals = rhrSeriesThroughDay.map(\.value)
        guard vals.count >= 2 else { return nil }
        return TrendAnalysisEngine.coefficientOfVariation(values: vals)
    }


    /// Honest #316: Strain CV% through day (Sleep #275 / HRV #285 / RHR #300 dual).
    private var strainCoefficientOfVariation: Double? {
        let vals = strainSeriesThroughDay.map(\.value)
        guard vals.count >= 2 else { return nil }
        return TrendAnalysisEngine.coefficientOfVariation(values: vals)
    }

    /// Honest #331: SpO2 CV% through day (Sleep #275 / Strain #316 dual).
    private var spo2CoefficientOfVariation: Double? {
        let vals = spo2SeriesThroughDay.map(\.value)
        guard vals.count >= 2 else { return nil }
        return TrendAnalysisEngine.coefficientOfVariation(values: vals)
    }


    /// Honest #279/#281: MA7 / MA14 / EMA7 for Sleep Trend overlays (always-on).
    private var sleepOverlaySeries: [(date: Date, ma7: Double?, ma14: Double?, ema: Double?)] {
        sevenDayWindow.compactMap { day in
            guard let point = sleepAnalyzedThroughDay.first(where: {
                Calendar.current.isDate($0.date, inSameDayAs: day.date)
            }) else { return nil }
            return (day.date, point.movingAverage7, point.movingAverage14, point.ema7)
        }
    }


    /// Honest #288/#289: MA7 / MA14 / EMA7 for HRV Trend overlays (always-on; Sleep #279/#281 dual).
    private var hrvOverlaySeries: [(date: Date, ma7: Double?, ma14: Double?, ema: Double?)] {
        sevenDayWindow.compactMap { day in
            guard let point = hrvAnalyzedThroughDay.first(where: {
                Calendar.current.isDate($0.date, inSameDayAs: day.date)
            }) else { return nil }
            return (day.date, point.movingAverage7, point.movingAverage14, point.ema7)
        }
    }


    /// Honest #303/#304: MA7 / MA14 / EMA7 for RHR Trend overlays (always-on; Sleep #279/#281 dual).
    private var rhrOverlaySeries: [(date: Date, ma7: Double?, ma14: Double?, ema: Double?)] {
        sevenDayWindow.compactMap { day in
            guard let point = rhrAnalyzedThroughDay.first(where: {
                Calendar.current.isDate($0.date, inSameDayAs: day.date)
            }) else { return nil }
            return (day.date, point.movingAverage7, point.movingAverage14, point.ema7)
        }
    }


    /// Honest #319/#320: MA7 / MA14 / EMA7 for Strain Trend overlays (always-on; Sleep #279/#281 dual).
    private var strainOverlaySeries: [(date: Date, ma7: Double?, ma14: Double?, ema: Double?)] {
        sevenDayWindow.compactMap { day in
            guard let point = strainAnalyzedThroughDay.first(where: {
                Calendar.current.isDate($0.date, inSameDayAs: day.date)
            }) else { return nil }
            return (day.date, point.movingAverage7, point.movingAverage14, point.ema7)
        }
    }

    /// Honest #334/#335: MA7 / MA14 / EMA7 for SpO2 Trend overlays (always-on; Sleep #279/#281 / Strain #319/#320 dual).
    private var spo2OverlaySeries: [(date: Date, ma7: Double?, ma14: Double?, ema: Double?)] {
        sevenDayWindow.compactMap { day in
            guard let point = spo2AnalyzedThroughDay.first(where: {
                Calendar.current.isDate($0.date, inSameDayAs: day.date)
            }) else { return nil }
            return (day.date, point.movingAverage7, point.movingAverage14, point.ema7)
        }
    }

    /// Honest #280: % vs baseline for selected day's Sleep (scrub-enrichment parity).
    private var sleepDayAnalyzed: AnalyzedDataPoint? {
        sleepAnalyzedThroughDay.first {
            Calendar.current.isDate($0.date, inSameDayAs: data.date)
        }
    }

    private var sleepPercentDeviationLabel: String? {
        guard let a = sleepDayAnalyzed else { return nil }
        let d = a.percentDeviation * 100
        let sign = d >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", d))% vs baseline"
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

                // Honest #274: classifyTrend strength callout on Sleep (classic #253 / Trends #255).
                if let strength = sleepTrendClassification {
                    dayDetailClassifyTrendCallout(strength)
                        .slideIn(delay: 0.21)
                }

                // Honest #283: classifyTrend strength callout on HRV (Sleep #274 dual).
                if let strength = hrvTrendClassification {
                    dayDetailHRVClassifyTrendCallout(strength)
                        .slideIn(delay: 0.212)
                }


                // Honest #298: classifyTrend strength callout on RHR (Sleep #274 / HRV #283 dual).
                if let strength = rhrTrendClassification {
                    dayDetailRHRClassifyTrendCallout(strength)
                        .slideIn(delay: 0.2125)
                }


                // Honest #314: classifyTrend strength callout on Strain (Sleep #274 / HRV #283 / RHR #298 dual).
                if let strength = strainTrendClassification {
                    dayDetailStrainClassifyTrendCallout(strength)
                        .slideIn(delay: 0.2126)
                }

                // Honest #329: classifyTrend strength callout on SpO2 (Sleep #274 / Strain #314 dual).
                if let strength = spo2TrendClassification {
                    dayDetailSpO2ClassifyTrendCallout(strength)
                        .slideIn(delay: 0.21262)
                }

                // Honest #330: SpO2 % vs baseline (percentDeviation; Sleep #280 / Strain #315 dual).
                if let label = spo2PercentDeviationLabel {
                    dayDetailSpO2PercentDeviationCallout(label)
                        .slideIn(delay: 0.21263)
                }


                // Honest #315: Strain % vs baseline (percentDeviation; Sleep #280 / HRV #284 / RHR #299 dual).
                if let label = strainPercentDeviationLabel {
                    dayDetailStrainPercentDeviationCallout(label)
                        .slideIn(delay: 0.21265)
                }


                // Honest #299: RHR % vs baseline (percentDeviation; Sleep #280 / HRV #284 dual).
                if let label = rhrPercentDeviationLabel {
                    dayDetailRHRPercentDeviationCallout(label)
                        .slideIn(delay: 0.2127)
                }


                // Honest #300: Statistics CV% on RHR (Sleep #275 / HRV #285 dual).
                if let cv = rhrCoefficientOfVariation {
                    dayDetailRHRStatsCVSection(cv: cv)
                        .slideIn(delay: 0.2128)
                }

                // Honest #316: Statistics CV% on Strain (Sleep #275 / HRV #285 / RHR #300 dual).
                if let cv = strainCoefficientOfVariation {
                    dayDetailStrainStatsCVSection(cv: cv)
                        .slideIn(delay: 0.2129)
                }

                // Honest #331: Statistics CV% on SpO2 (Sleep #275 / Strain #316 dual).
                if let cv = spo2CoefficientOfVariation {
                    dayDetailSpO2StatsCVSection(cv: cv)
                        .slideIn(delay: 0.21295)
                }

                // Honest #284: HRV % vs baseline (percentDeviation; Sleep #280 dual).
                if let label = hrvPercentDeviationLabel {
                    dayDetailHRVPercentDeviationCallout(label)
                        .slideIn(delay: 0.213)
                }

                // Honest #285: Statistics CV% on HRV (Sleep #275 dual).
                if let cv = hrvCoefficientOfVariation {
                    dayDetailHRVStatsCVSection(cv: cv)
                        .slideIn(delay: 0.214)
                }

                // Honest #275: Statistics CV% on Sleep (classic #254 / Trends #256 parity).
                if let cv = sleepCoefficientOfVariation {
                    dayDetailStatsCVSection(cv: cv)
                        .slideIn(delay: 0.215)
                }

                // Honest #276: rollingVolatility strip on Sleep (classic #248 / Trends #259 parity).
                dayDetailVolatilitySection
                    .slideIn(delay: 0.217)

                // Honest #291: rollingVolatility strip on HRV (Sleep #276 dual).
                dayDetailHRVVolatilitySection
                    .slideIn(delay: 0.218)

                // Honest #305: rollingVolatility strip on RHR (Sleep #276 / HRV #291 dual; strip triad start).
                dayDetailRHRVolatilitySection
                    .slideIn(delay: 0.219)

                // Honest #321: rollingVolatility strip on Strain (Sleep #276 / HRV #291 / RHR #305 dual; strip triad start).
                dayDetailStrainVolatilitySection
                    .slideIn(delay: 0.2195)

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


                // Honest #290: SmartInsightsView on HRV series (Sleep #267 dual; ≥3 points).
                if hrvSeriesThroughDay.count >= 3 {
                    SmartInsightsView(
                        metric: .hrv,
                        history: hrvSeriesThroughDay,
                        currentValue: data.hrv
                    )
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier(SurfaceID.dayDetailHRVSmartInsights)
                    .slideIn(delay: 0.222)
                }


                // Honest #296: SmartInsightsView on RHR series (thinnest RHR track; ≥3).
                if rhrSeriesThroughDay.count >= 3 {
                    SmartInsightsView(
                        metric: .restingHR,
                        history: rhrSeriesThroughDay,
                        currentValue: data.restingHeartRate
                    )
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier(SurfaceID.dayDetailRHRSmartInsights)
                    .slideIn(delay: 0.223)
                }

                // Honest #311: SmartInsightsView on Strain/activeCalories (Sleep #267 / HRV #290 / RHR #296 dual; ≥3).
                if strainSeriesThroughDay.count >= 3 {
                    SmartInsightsView(
                        metric: .activeCalories,
                        history: strainSeriesThroughDay,
                        currentValue: data.activeCalories
                    )
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier(SurfaceID.dayDetailStrainSmartInsights)
                    .slideIn(delay: 0.224)
                }

                // Honest #326: SmartInsightsView on SpO2 (Sleep #267 / Strain #311 dual; ≥3 optional points).
                if spo2SeriesThroughDay.count >= 3, let spo2 = data.bloodOxygen ?? spo2SeriesThroughDay.last?.value {
                    SmartInsightsView(
                        metric: .bloodOxygen,
                        history: spo2SeriesThroughDay,
                        currentValue: spo2
                    )
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier(SurfaceID.dayDetailSpO2SmartInsights)
                    .slideIn(delay: 0.225)
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


                // Honest #294: WeeklyPatternView on HRV series (Sleep #268 dual; ≥7).
                if hrvSeriesThroughDay.count >= 7 {
                    WeeklyPatternView(
                        history: hrvSeriesThroughDay,
                        metric: .hrv
                    )
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier(SurfaceID.dayDetailHRVWeeklyPattern)
                    .slideIn(delay: 0.232)
                }

                // Honest #308: WeeklyPatternView on RHR series (Sleep #268 / HRV #294 dual; ≥7).
                if rhrSeriesThroughDay.count >= 7 {
                    WeeklyPatternView(
                        history: rhrSeriesThroughDay,
                        metric: .restingHR
                    )
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier(SurfaceID.dayDetailRHRWeeklyPattern)
                    .slideIn(delay: 0.234)
                }

                // Honest #312: WeeklyPatternView on Strain/activeCalories (Sleep #268 / HRV #294 / RHR #308 dual; ≥7).
                if strainSeriesThroughDay.count >= 7 {
                    WeeklyPatternView(
                        history: strainSeriesThroughDay,
                        metric: .activeCalories
                    )
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier(SurfaceID.dayDetailStrainWeeklyPattern)
                    .slideIn(delay: 0.236)


                // Honest #327: WeeklyPatternView on SpO2 (Sleep #268 / Strain #312 dual; ≥7 optional points).
                if spo2SeriesThroughDay.count >= 7 {
                    WeeklyPatternView(
                        history: spo2SeriesThroughDay,
                        metric: .bloodOxygen
                    )
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier(SurfaceID.dayDetailSpO2WeeklyPattern)
                    .slideIn(delay: 0.234)
                }
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


                // Honest #295: RecoveryTrajectoryView on HRV (Sleep #269 dual; ≥5 + strain).
                if hrvSeriesThroughDay.count >= 5 {
                    RecoveryTrajectoryView(
                        history: hrvSeriesThroughDay,
                        strainHistory: strainSeriesThroughDay,
                        metric: .hrv
                    )
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier(SurfaceID.dayDetailHRVRecoveryTrajectory)
                    .slideIn(delay: 0.242)
                }

                // Honest #309: RecoveryTrajectoryView on RHR (Sleep #269 / HRV #295 dual; ≥5 + strain).
                if rhrSeriesThroughDay.count >= 5 {
                    RecoveryTrajectoryView(
                        history: rhrSeriesThroughDay,
                        strainHistory: strainSeriesThroughDay,
                        metric: .restingHR
                    )
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier(SurfaceID.dayDetailRHRRecoveryTrajectory)
                    .slideIn(delay: 0.244)
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

                // Honest #310: MetricCorrelationView HRV↔RHR (extends #270; MetricDetail restingHR↔hrv parity).
                if historyThroughDay.count >= 3 {
                    MetricCorrelationView(
                        history: historyThroughDay,
                        xMetric: .hrv,
                        yMetric: .restingHR
                    )
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier(SurfaceID.dayDetailMetricCorrelationHRVRHR)
                    .slideIn(delay: 0.246)
                }

                // Honest #324: MetricCorrelationView Sleep↔RHR (extends #270/#310 triad).
                if historyThroughDay.count >= 3 {
                    MetricCorrelationView(
                        history: historyThroughDay,
                        xMetric: .sleep,
                        yMetric: .restingHR
                    )
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier(SurfaceID.dayDetailMetricCorrelationSleepRHR)
                    .slideIn(delay: 0.2465)
                }

                // Honest #325: MetricCorrelationView Sleep↔Strain (extends #270/#310/#324).
                if historyThroughDay.count >= 3 {
                    MetricCorrelationView(
                        history: historyThroughDay,
                        xMetric: .sleep,
                        yMetric: .activeCalories
                    )
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier(SurfaceID.dayDetailMetricCorrelationSleepStrain)
                    .slideIn(delay: 0.2467)
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

                // Honest #282: DistributionHistogramView on HRV (Sleep #271 dual).
                if hrvSeriesThroughDay.count >= 5 {
                    DistributionHistogramView(
                        history: hrvSeriesThroughDay,
                        metric: .hrv
                    )
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier(SurfaceID.dayDetailHRVHistogram)
                    .slideIn(delay: 0.2475)
                }


                // Honest #297: DistributionHistogramView on RHR (Sleep #271 / HRV #282 dual).
                if rhrSeriesThroughDay.count >= 5 {
                    DistributionHistogramView(
                        history: rhrSeriesThroughDay,
                        metric: .restingHR
                    )
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier(SurfaceID.dayDetailRHRHistogram)
                    .slideIn(delay: 0.2476)
                }

                // Honest #313: DistributionHistogramView on Strain (Sleep #271 / HRV #282 / RHR #297 dual).
                if strainSeriesThroughDay.count >= 5 {
                    DistributionHistogramView(
                        history: strainSeriesThroughDay,
                        metric: .activeCalories
                    )
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier(SurfaceID.dayDetailStrainHistogram)
                    .slideIn(delay: 0.2477)
                }

                // Honest #328: DistributionHistogramView on SpO2 (Sleep #271 / Strain #313 dual; ≥5 optional points).
                if spo2SeriesThroughDay.count >= 5 {
                    DistributionHistogramView(
                        history: spo2SeriesThroughDay,
                        metric: .bloodOxygen
                    )
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier(SurfaceID.dayDetailSpO2Histogram)
                    .slideIn(delay: 0.24775)
                }

                // Honest #286: OutlierCallout Highlights on HRV (Sleep #272 dual).
                dayDetailHRVOutlierSection
                    .slideIn(delay: 0.2478)


                // Honest #301: OutlierCallout Highlights on RHR (Sleep #272 / HRV #286 dual).
                dayDetailRHROutlierSection
                    .slideIn(delay: 0.2479)

                // Honest #317: OutlierCallout Highlights on Strain (Sleep #272 / HRV #286 / RHR #301 dual).
                dayDetailStrainOutlierSection
                    .slideIn(delay: 0.24795)

                // Honest #332: OutlierCallout Highlights on SpO2 (Sleep #272 / Strain #317 dual).
                dayDetailSpO2OutlierSection
                    .slideIn(delay: 0.24796)

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
    





    // MARK: - Rolling Volatility (Honest #276)
    private var dayDetailVolatilityPoints: [(date: Date, cv: Double)] {
        sleepAnalyzedThroughDay.compactMap { point in
            guard let cv = point.volatility else { return nil }
            return (point.date, cv)
        }
    }

    private var dayDetailLatestVolatilityBand: (label: String, color: Color) {
        guard let cv = dayDetailVolatilityPoints.last?.cv else {
            return ("—", RTColor.secondaryText)
        }
        if cv >= 0.15 { return ("High", RTColor.warning) }
        if cv >= 0.08 { return ("Mild", RTColor.caution) }
        return ("Low", RTColor.optimal)
    }

    private var dayDetailVolatilityYDomain: ClosedRange<Double> {
        let vals = dayDetailVolatilityPoints.map(\.cv)
        let hi = max(vals.max() ?? 0.2, 0.2)
        return 0...(hi * 1.15)
    }

    private var dayDetailVolatilitySection: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    ToggleChip(label: "Volatility", isOn: $showVolatility)
                        .accessibilityIdentifier(SurfaceID.dayDetailVolatilityToggle)
                    ToggleChip(label: "Momentum", isOn: $showMomentum)
                        .accessibilityIdentifier(SurfaceID.dayDetailMomentumToggle)
                    ToggleChip(label: "Day Δ", isOn: $showRateOfChange)
                        .accessibilityIdentifier(SurfaceID.dayDetailDayDeltaToggle)
                    Spacer(minLength: 0)
                }

                if showVolatility {
                    dayDetailVolatilityStrip
                }
                // Honest #277: elevate unused AnalyzedDataPoint.momentum (Trends #260 parity).
                if showMomentum {
                    dayDetailMomentumStrip
                }
                // Honest #278: elevate unused AnalyzedDataPoint.rateOfChange (Day Δ / Trends #261).
                if showRateOfChange {
                    dayDetailDayDeltaStrip
                }
            }
        }
    }

    private var dayDetailVolatilityStrip: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("7-Day Volatility")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
                Spacer()
                if let cv = dayDetailVolatilityPoints.last?.cv {
                    Text(String(format: "CV %.0f%% · %@", cv * 100, dayDetailLatestVolatilityBand.label))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(dayDetailLatestVolatilityBand.color)
                        .monospacedDigit()
                }
            }

            if !dayDetailVolatilityPoints.isEmpty {
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
                        yEnd: .value("HighTop", dayDetailVolatilityYDomain.upperBound)
                    )
                    .foregroundStyle(RTColor.warning.opacity(0.08))

                    ForEach(Array(dayDetailVolatilityPoints.enumerated()), id: \.offset) { _, point in
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
                .chartYScale(domain: dayDetailVolatilityYDomain)
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
        .accessibilityIdentifier(SurfaceID.dayDetailVolatility)
        .accessibilityLabel("Seven day rolling volatility")
    }


    // MARK: - HRV Rolling Volatility (Honest #291)
    private var dayDetailHRVVolatilityPoints: [(date: Date, cv: Double)] {
        hrvAnalyzedThroughDay.compactMap { point in
            guard let cv = point.volatility else { return nil }
            return (point.date, cv)
        }
    }

    private var dayDetailHRVLatestVolatilityBand: (label: String, color: Color) {
        guard let cv = dayDetailHRVVolatilityPoints.last?.cv else {
            return ("—", RTColor.secondaryText)
        }
        if cv >= 0.15 { return ("High", RTColor.warning) }
        if cv >= 0.08 { return ("Mild", RTColor.caution) }
        return ("Low", RTColor.optimal)
    }

    private var dayDetailHRVVolatilityYDomain: ClosedRange<Double> {
        let vals = dayDetailHRVVolatilityPoints.map(\.cv)
        let hi = max(vals.max() ?? 0.2, 0.2)
        return 0...(hi * 1.15)
    }

    private var dayDetailHRVVolatilitySection: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    ToggleChip(label: "HRV Volatility", isOn: $showHRVVolatility)
                        .accessibilityIdentifier(SurfaceID.dayDetailHRVVolatilityToggle)
                    ToggleChip(label: "HRV Momentum", isOn: $showHRVMomentum)
                        .accessibilityIdentifier(SurfaceID.dayDetailHRVMomentumToggle)
                    ToggleChip(label: "HRV Day Δ", isOn: $showHRVRateOfChange)
                        .accessibilityIdentifier(SurfaceID.dayDetailHRVDayDeltaToggle)
                    Spacer(minLength: 0)
                }

                if showHRVVolatility {
                    dayDetailHRVVolatilityStrip
                }
                // Honest #292: elevate unused AnalyzedDataPoint.momentum on HRV (Sleep #277 dual).
                if showHRVMomentum {
                    dayDetailHRVMomentumStrip
                }
                // Honest #293: elevate unused AnalyzedDataPoint.rateOfChange on HRV (Sleep #278 dual).
                if showHRVRateOfChange {
                    dayDetailHRVDayDeltaStrip
                }
            }
        }
    }

    private var dayDetailHRVVolatilityStrip: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("7-Day HRV Volatility")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
                Spacer()
                if let cv = dayDetailHRVVolatilityPoints.last?.cv {
                    Text(String(format: "CV %.0f%% · %@", cv * 100, dayDetailHRVLatestVolatilityBand.label))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(dayDetailHRVLatestVolatilityBand.color)
                        .monospacedDigit()
                }
            }

            if !dayDetailHRVVolatilityPoints.isEmpty {
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
                        yEnd: .value("HighTop", dayDetailHRVVolatilityYDomain.upperBound)
                    )
                    .foregroundStyle(RTColor.warning.opacity(0.08))

                    ForEach(Array(dayDetailHRVVolatilityPoints.enumerated()), id: \.offset) { _, point in
                        AreaMark(
                            x: .value("Date", point.date, unit: .day),
                            y: .value("CV", point.cv)
                        )
                        .foregroundStyle(RTColor.hrv.opacity(0.18))
                        .interpolationMethod(.catmullRom)

                        LineMark(
                            x: .value("Date", point.date, unit: .day),
                            y: .value("CV", point.cv)
                        )
                        .foregroundStyle(RTColor.hrv)
                        .lineStyle(StrokeStyle(lineWidth: 1.5))
                        .interpolationMethod(.catmullRom)
                    }
                }
                .frame(height: 72)
                .chartYScale(domain: dayDetailHRVVolatilityYDomain)
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
                Text("Need ≥7 days for HRV volatility")
                    .font(.caption)
                    .foregroundStyle(RTColor.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(height: 72)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(SurfaceID.dayDetailHRVVolatility)
        .accessibilityLabel("Seven day HRV rolling volatility")
    }

    // MARK: - RHR Rolling Volatility (Honest #305)
    private var dayDetailRHRVolatilityPoints: [(date: Date, cv: Double)] {
        rhrAnalyzedThroughDay.compactMap { point in
            guard let cv = point.volatility else { return nil }
            return (point.date, cv)
        }
    }

    private var dayDetailRHRLatestVolatilityBand: (label: String, color: Color) {
        guard let cv = dayDetailRHRVolatilityPoints.last?.cv else {
            return ("—", RTColor.secondaryText)
        }
        if cv >= 0.15 { return ("High", RTColor.warning) }
        if cv >= 0.08 { return ("Mild", RTColor.caution) }
        return ("Low", RTColor.optimal)
    }

    private var dayDetailRHRVolatilityYDomain: ClosedRange<Double> {
        let vals = dayDetailRHRVolatilityPoints.map(\.cv)
        let hi = max(vals.max() ?? 0.2, 0.2)
        return 0...(hi * 1.15)
    }

    private var dayDetailRHRVolatilitySection: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    ToggleChip(label: "RHR Volatility", isOn: $showRHRVolatility)
                        .accessibilityIdentifier(SurfaceID.dayDetailRHRVolatilityToggle)
                    ToggleChip(label: "RHR Momentum", isOn: $showRHRMomentum)
                        .accessibilityIdentifier(SurfaceID.dayDetailRHRMomentumToggle)
                    ToggleChip(label: "RHR Day Δ", isOn: $showRHRRateOfChange)
                        .accessibilityIdentifier(SurfaceID.dayDetailRHRDayDeltaToggle)
                    Spacer(minLength: 0)
                }

                if showRHRVolatility {
                    dayDetailRHRVolatilityStrip
                }
                // Honest #306: elevate unused AnalyzedDataPoint.momentum on RHR (Sleep #277 / HRV #292 dual).
                if showRHRMomentum {
                    dayDetailRHRMomentumStrip
                }
                // Honest #307: elevate unused AnalyzedDataPoint.rateOfChange on RHR (Sleep #278 / HRV #293 dual).
                if showRHRRateOfChange {
                    dayDetailRHRDayDeltaStrip
                }
            }
        }
    }

    private var dayDetailRHRVolatilityStrip: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("7-Day RHR Volatility")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
                Spacer()
                if let cv = dayDetailRHRVolatilityPoints.last?.cv {
                    Text(String(format: "CV %.0f%% · %@", cv * 100, dayDetailRHRLatestVolatilityBand.label))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(dayDetailRHRLatestVolatilityBand.color)
                        .monospacedDigit()
                }
            }

            if !dayDetailRHRVolatilityPoints.isEmpty {
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
                        yEnd: .value("HighTop", dayDetailRHRVolatilityYDomain.upperBound)
                    )
                    .foregroundStyle(RTColor.warning.opacity(0.08))

                    ForEach(Array(dayDetailRHRVolatilityPoints.enumerated()), id: \.offset) { _, point in
                        AreaMark(
                            x: .value("Date", point.date, unit: .day),
                            y: .value("CV", point.cv)
                        )
                        .foregroundStyle(RTColor.strain.opacity(0.18))
                        .interpolationMethod(.catmullRom)

                        LineMark(
                            x: .value("Date", point.date, unit: .day),
                            y: .value("CV", point.cv)
                        )
                        .foregroundStyle(RTColor.strain)
                        .lineStyle(StrokeStyle(lineWidth: 1.5))
                        .interpolationMethod(.catmullRom)
                    }
                }
                .frame(height: 72)
                .chartYScale(domain: dayDetailRHRVolatilityYDomain)
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
                Text("Need ≥7 days for RHR volatility")
                    .font(.caption)
                    .foregroundStyle(RTColor.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(height: 72)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(SurfaceID.dayDetailRHRVolatility)
        .accessibilityLabel("Seven day RHR rolling volatility")
    }

    // MARK: - Strain Rolling Volatility (Honest #321)
    private var dayDetailStrainVolatilityPoints: [(date: Date, cv: Double)] {
        strainAnalyzedThroughDay.compactMap { point in
            guard let cv = point.volatility else { return nil }
            return (point.date, cv)
        }
    }

    private var dayDetailStrainLatestVolatilityBand: (label: String, color: Color) {
        guard let cv = dayDetailStrainVolatilityPoints.last?.cv else {
            return ("—", RTColor.secondaryText)
        }
        if cv >= 0.15 { return ("High", RTColor.warning) }
        if cv >= 0.08 { return ("Mild", RTColor.caution) }
        return ("Low", RTColor.optimal)
    }

    private var dayDetailStrainVolatilityYDomain: ClosedRange<Double> {
        let vals = dayDetailStrainVolatilityPoints.map(\.cv)
        let hi = max(vals.max() ?? 0.2, 0.2)
        return 0...(hi * 1.15)
    }

    private var dayDetailStrainVolatilitySection: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    ToggleChip(label: "Strain Volatility", isOn: $showStrainVolatility)
                        .accessibilityIdentifier(SurfaceID.dayDetailStrainVolatilityToggle)
                    ToggleChip(label: "Strain Momentum", isOn: $showStrainMomentum)
                        .accessibilityIdentifier(SurfaceID.dayDetailStrainMomentumToggle)
                    ToggleChip(label: "Strain Day Δ", isOn: $showStrainRateOfChange)
                        .accessibilityIdentifier(SurfaceID.dayDetailStrainDayDeltaToggle)
                    Spacer(minLength: 0)
                }

                if showStrainVolatility {
                    dayDetailStrainVolatilityStrip
                }
                // Honest #322: elevate unused AnalyzedDataPoint.momentum on Strain (Sleep #277 / HRV #292 / RHR #306 dual).
                if showStrainMomentum {
                    dayDetailStrainMomentumStrip
                }
                // Honest #323: elevate unused AnalyzedDataPoint.rateOfChange on Strain (Sleep #278 / HRV #293 / RHR #307 dual).
                if showStrainRateOfChange {
                    dayDetailStrainDayDeltaStrip
                }
            }
        }
    }

    private var dayDetailStrainVolatilityStrip: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("7-Day Strain Volatility")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
                Spacer()
                if let cv = dayDetailStrainVolatilityPoints.last?.cv {
                    Text(String(format: "CV %.0f%% · %@", cv * 100, dayDetailStrainLatestVolatilityBand.label))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(dayDetailStrainLatestVolatilityBand.color)
                        .monospacedDigit()
                }
            }

            if !dayDetailStrainVolatilityPoints.isEmpty {
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
                        yEnd: .value("HighTop", dayDetailStrainVolatilityYDomain.upperBound)
                    )
                    .foregroundStyle(RTColor.warning.opacity(0.08))

                    ForEach(Array(dayDetailStrainVolatilityPoints.enumerated()), id: \.offset) { _, point in
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
                .chartYScale(domain: dayDetailStrainVolatilityYDomain)
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
                Text("Need ≥7 days for Strain volatility")
                    .font(.caption)
                    .foregroundStyle(RTColor.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(height: 72)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(SurfaceID.dayDetailStrainVolatility)
        .accessibilityLabel("Seven day Strain rolling volatility")
    }

    // MARK: - Strain Momentum (Honest #322)
    private var dayDetailStrainMomentumPoints: [(date: Date, mom: Double)] {
        strainAnalyzedThroughDay.compactMap { point in
            guard let mom = point.momentum else { return nil }
            return (point.date, mom)
        }
    }

    private var dayDetailStrainLatestMomentumBand: (label: String, color: Color) {
        guard let mom = dayDetailStrainMomentumPoints.last?.mom else {
            return ("—", RTColor.secondaryText)
        }
        // Strain/activeCalories: higherIsBetter — rising momentum is improving.
        let improving = mom > 0
        if abs(mom) < 0.05 { return ("Flat", RTColor.secondaryText) }
        if improving { return ("Rising", RTColor.optimal) }
        return ("Fading", RTColor.warning)
    }

    private var dayDetailStrainMomentumYDomain: ClosedRange<Double> {
        let vals = dayDetailStrainMomentumPoints.map(\.mom)
        let lo = min(vals.min() ?? -0.2, -0.2)
        let hi = max(vals.max() ?? 0.2, 0.2)
        let pad = max((hi - lo) * 0.1, 0.05)
        return (lo - pad)...(hi + pad)
    }

    private var dayDetailStrainMomentumStrip: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("7-Day Strain Momentum")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
                Spacer()
                if let mom = dayDetailStrainMomentumPoints.last?.mom {
                    let sign = mom >= 0 ? "+" : ""
                    Text(String(format: "%@%.0f%% · %@", sign, mom * 100, dayDetailStrainLatestMomentumBand.label))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(dayDetailStrainLatestMomentumBand.color)
                        .monospacedDigit()
                }
            }

            if !dayDetailStrainMomentumPoints.isEmpty {
                Chart {
                    RuleMark(y: .value("Zero", 0))
                        .foregroundStyle(RTColor.tertiaryText.opacity(0.6))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))

                    ForEach(Array(dayDetailStrainMomentumPoints.enumerated()), id: \.offset) { _, point in
                        AreaMark(
                            x: .value("Date", point.date, unit: .day),
                            yStart: .value("Zero", 0),
                            yEnd: .value("Mom", point.mom)
                        )
                        .foregroundStyle(
                            point.mom >= 0
                                ? RTColor.optimal.opacity(0.18)
                                : RTColor.warning.opacity(0.18)
                        )

                        LineMark(
                            x: .value("Date", point.date, unit: .day),
                            y: .value("Mom", point.mom)
                        )
                        .foregroundStyle(RTColor.caution)
                        .lineStyle(StrokeStyle(lineWidth: 1.5))
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Date", point.date, unit: .day),
                            y: .value("Mom", point.mom)
                        )
                        .foregroundStyle(RTColor.caution)
                        .symbolSize(20)
                    }
                }
                .frame(height: 72)
                .chartYScale(domain: dayDetailStrainMomentumYDomain)
                .chartXAxis(.hidden)
                .chartYAxis {
                    AxisMarks(position: .leading, values: [dayDetailStrainMomentumYDomain.lowerBound, 0, dayDetailStrainMomentumYDomain.upperBound]) { value in
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
                Text("Need ≥8 days for Strain momentum")
                    .font(.caption)
                    .foregroundStyle(RTColor.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(height: 72)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(SurfaceID.dayDetailStrainMomentum)
        .accessibilityLabel("Seven day Strain momentum")
    }

    // MARK: - Strain Day Δ / rateOfChange (Honest #323)
    private var dayDetailStrainROCPoints: [(date: Date, roc: Double)] {
        strainAnalyzedThroughDay.compactMap { point in
            guard let roc = point.rateOfChange else { return nil }
            return (point.date, roc)
        }
    }

    private var dayDetailStrainLatestROCBand: (label: String, color: Color) {
        guard let roc = dayDetailStrainROCPoints.last?.roc else {
            return ("—", RTColor.secondaryText)
        }
        // Strain/activeCalories: higherIsBetter — Up when ROC > 0.
        let improving = roc > 0
        if abs(roc) < 0.03 { return ("Flat", RTColor.secondaryText) }
        if improving { return ("Up", RTColor.optimal) }
        return ("Down", RTColor.warning)
    }

    private var dayDetailStrainROCYDomain: ClosedRange<Double> {
        let vals = dayDetailStrainROCPoints.map(\.roc)
        let lo = min(vals.min() ?? -0.25, -0.25)
        let hi = max(vals.max() ?? 0.25, 0.25)
        let pad = max((hi - lo) * 0.1, 0.05)
        return (lo - pad)...(hi + pad)
    }

    private var dayDetailStrainDayDeltaStrip: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Strain Day-over-Day Change")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
                Spacer()
                if let roc = dayDetailStrainROCPoints.last?.roc {
                    let sign = roc >= 0 ? "+" : ""
                    Text(String(format: "%@%.0f%% · %@", sign, roc * 100, dayDetailStrainLatestROCBand.label))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(dayDetailStrainLatestROCBand.color)
                        .monospacedDigit()
                }
            }

            if !dayDetailStrainROCPoints.isEmpty {
                Chart {
                    RuleMark(y: .value("Zero", 0))
                        .foregroundStyle(RTColor.tertiaryText.opacity(0.6))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))

                    ForEach(Array(dayDetailStrainROCPoints.enumerated()), id: \.offset) { _, point in
                        BarMark(
                            x: .value("Date", point.date, unit: .day),
                            y: .value("ROC", point.roc)
                        )
                        .foregroundStyle(
                            point.roc >= 0
                                ? RTColor.optimal.opacity(0.75)
                                : RTColor.warning.opacity(0.75)
                        )
                        .cornerRadius(2)
                    }
                }
                .frame(height: 72)
                .chartYScale(domain: dayDetailStrainROCYDomain)
                .chartXAxis(.hidden)
                .chartYAxis {
                    AxisMarks(position: .leading, values: [dayDetailStrainROCYDomain.lowerBound, 0, dayDetailStrainROCYDomain.upperBound]) { value in
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
                Text("Need ≥2 days for Strain day-over-day change")
                    .font(.caption)
                    .foregroundStyle(RTColor.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(height: 72)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(SurfaceID.dayDetailStrainDayDelta)
        .accessibilityLabel("Strain day over day rate of change")
    }


    // MARK: - RHR Momentum (Honest #306)
    private var dayDetailRHRMomentumPoints: [(date: Date, mom: Double)] {
        rhrAnalyzedThroughDay.compactMap { point in
            guard let mom = point.momentum else { return nil }
            return (point.date, mom)
        }
    }

    private var dayDetailRHRLatestMomentumBand: (label: String, color: Color) {
        guard let mom = dayDetailRHRMomentumPoints.last?.mom else {
            return ("—", RTColor.secondaryText)
        }
        // RHR: lowerIsBetter — falling momentum is improving.
        let improving = mom < 0
        if abs(mom) < 0.05 { return ("Flat", RTColor.secondaryText) }
        if improving { return ("Falling", RTColor.optimal) }
        return ("Rising", RTColor.warning)
    }

    private var dayDetailRHRMomentumYDomain: ClosedRange<Double> {
        let vals = dayDetailRHRMomentumPoints.map(\.mom)
        let lo = min(vals.min() ?? -0.2, -0.2)
        let hi = max(vals.max() ?? 0.2, 0.2)
        let pad = max((hi - lo) * 0.1, 0.05)
        return (lo - pad)...(hi + pad)
    }

    private var dayDetailRHRMomentumStrip: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("7-Day RHR Momentum")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
                Spacer()
                if let mom = dayDetailRHRMomentumPoints.last?.mom {
                    let sign = mom >= 0 ? "+" : ""
                    Text(String(format: "%@%.0f%% · %@", sign, mom * 100, dayDetailRHRLatestMomentumBand.label))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(dayDetailRHRLatestMomentumBand.color)
                        .monospacedDigit()
                }
            }

            if !dayDetailRHRMomentumPoints.isEmpty {
                Chart {
                    RuleMark(y: .value("Zero", 0))
                        .foregroundStyle(RTColor.tertiaryText.opacity(0.6))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))

                    ForEach(Array(dayDetailRHRMomentumPoints.enumerated()), id: \.offset) { _, point in
                        AreaMark(
                            x: .value("Date", point.date, unit: .day),
                            yStart: .value("Zero", 0),
                            yEnd: .value("Mom", point.mom)
                        )
                        .foregroundStyle(
                            // RHR lowerIsBetter: falling (mom < 0) is optimal.
                            point.mom < 0
                                ? RTColor.optimal.opacity(0.18)
                                : RTColor.warning.opacity(0.18)
                        )

                        LineMark(
                            x: .value("Date", point.date, unit: .day),
                            y: .value("Mom", point.mom)
                        )
                        .foregroundStyle(RTColor.strain)
                        .lineStyle(StrokeStyle(lineWidth: 1.5))
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Date", point.date, unit: .day),
                            y: .value("Mom", point.mom)
                        )
                        .foregroundStyle(RTColor.strain)
                        .symbolSize(20)
                    }
                }
                .frame(height: 72)
                .chartYScale(domain: dayDetailRHRMomentumYDomain)
                .chartXAxis(.hidden)
                .chartYAxis {
                    AxisMarks(position: .leading, values: [dayDetailRHRMomentumYDomain.lowerBound, 0, dayDetailRHRMomentumYDomain.upperBound]) { value in
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
                Text("Need ≥8 days for RHR momentum")
                    .font(.caption)
                    .foregroundStyle(RTColor.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(height: 72)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(SurfaceID.dayDetailRHRMomentum)
        .accessibilityLabel("Seven day RHR momentum")
    }


    // MARK: - RHR Day Δ / rateOfChange (Honest #307)
    private var dayDetailRHRROCPoints: [(date: Date, roc: Double)] {
        rhrAnalyzedThroughDay.compactMap { point in
            guard let roc = point.rateOfChange else { return nil }
            return (point.date, roc)
        }
    }

    private var dayDetailRHRLatestROCBand: (label: String, color: Color) {
        guard let roc = dayDetailRHRROCPoints.last?.roc else {
            return ("—", RTColor.secondaryText)
        }
        // RHR: lowerIsBetter — Down when ROC < 0 is improving.
        let improving = roc < 0
        if abs(roc) < 0.03 { return ("Flat", RTColor.secondaryText) }
        if improving { return ("Down", RTColor.optimal) }
        return ("Up", RTColor.warning)
    }

    private var dayDetailRHRROCYDomain: ClosedRange<Double> {
        let vals = dayDetailRHRROCPoints.map(\.roc)
        let lo = min(vals.min() ?? -0.25, -0.25)
        let hi = max(vals.max() ?? 0.25, 0.25)
        let pad = max((hi - lo) * 0.1, 0.05)
        return (lo - pad)...(hi + pad)
    }

    private var dayDetailRHRDayDeltaStrip: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("RHR Day-over-Day Change")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
                Spacer()
                if let roc = dayDetailRHRROCPoints.last?.roc {
                    let sign = roc >= 0 ? "+" : ""
                    Text(String(format: "%@%.0f%% · %@", sign, roc * 100, dayDetailRHRLatestROCBand.label))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(dayDetailRHRLatestROCBand.color)
                        .monospacedDigit()
                }
            }

            if !dayDetailRHRROCPoints.isEmpty {
                Chart {
                    RuleMark(y: .value("Zero", 0))
                        .foregroundStyle(RTColor.tertiaryText.opacity(0.6))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))

                    ForEach(Array(dayDetailRHRROCPoints.enumerated()), id: \.offset) { _, point in
                        BarMark(
                            x: .value("Date", point.date, unit: .day),
                            y: .value("ROC", point.roc)
                        )
                        .foregroundStyle(
                            // RHR lowerIsBetter: Down (roc < 0) is optimal.
                            point.roc < 0
                                ? RTColor.optimal.opacity(0.75)
                                : RTColor.warning.opacity(0.75)
                        )
                        .cornerRadius(2)
                    }
                }
                .frame(height: 72)
                .chartYScale(domain: dayDetailRHRROCYDomain)
                .chartXAxis(.hidden)
                .chartYAxis {
                    AxisMarks(position: .leading, values: [dayDetailRHRROCYDomain.lowerBound, 0, dayDetailRHRROCYDomain.upperBound]) { value in
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
                Text("Need ≥2 days for RHR day-over-day change")
                    .font(.caption)
                    .foregroundStyle(RTColor.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(height: 72)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(SurfaceID.dayDetailRHRDayDelta)
        .accessibilityLabel("RHR day over day rate of change")
    }





    // MARK: - HRV Momentum (Honest #292)
    private var dayDetailHRVMomentumPoints: [(date: Date, mom: Double)] {
        hrvAnalyzedThroughDay.compactMap { point in
            guard let mom = point.momentum else { return nil }
            return (point.date, mom)
        }
    }

    private var dayDetailHRVLatestMomentumBand: (label: String, color: Color) {
        guard let mom = dayDetailHRVMomentumPoints.last?.mom else {
            return ("—", RTColor.secondaryText)
        }
        // HRV: higherIsBetter — rising momentum is improving.
        let improving = mom > 0
        if abs(mom) < 0.05 { return ("Flat", RTColor.secondaryText) }
        if improving { return ("Rising", RTColor.optimal) }
        return ("Fading", RTColor.warning)
    }

    private var dayDetailHRVMomentumYDomain: ClosedRange<Double> {
        let vals = dayDetailHRVMomentumPoints.map(\.mom)
        let lo = min(vals.min() ?? -0.2, -0.2)
        let hi = max(vals.max() ?? 0.2, 0.2)
        let pad = max((hi - lo) * 0.1, 0.05)
        return (lo - pad)...(hi + pad)
    }

    private var dayDetailHRVMomentumStrip: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("7-Day HRV Momentum")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
                Spacer()
                if let mom = dayDetailHRVMomentumPoints.last?.mom {
                    let sign = mom >= 0 ? "+" : ""
                    Text(String(format: "%@%.0f%% · %@", sign, mom * 100, dayDetailHRVLatestMomentumBand.label))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(dayDetailHRVLatestMomentumBand.color)
                        .monospacedDigit()
                }
            }

            if !dayDetailHRVMomentumPoints.isEmpty {
                Chart {
                    RuleMark(y: .value("Zero", 0))
                        .foregroundStyle(RTColor.tertiaryText.opacity(0.6))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))

                    ForEach(Array(dayDetailHRVMomentumPoints.enumerated()), id: \.offset) { _, point in
                        AreaMark(
                            x: .value("Date", point.date, unit: .day),
                            yStart: .value("Zero", 0),
                            yEnd: .value("Mom", point.mom)
                        )
                        .foregroundStyle(
                            point.mom >= 0
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
                .chartYScale(domain: dayDetailHRVMomentumYDomain)
                .chartXAxis(.hidden)
                .chartYAxis {
                    AxisMarks(position: .leading, values: [dayDetailHRVMomentumYDomain.lowerBound, 0, dayDetailHRVMomentumYDomain.upperBound]) { value in
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
                Text("Need ≥8 days for HRV momentum")
                    .font(.caption)
                    .foregroundStyle(RTColor.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(height: 72)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(SurfaceID.dayDetailHRVMomentum)
        .accessibilityLabel("Seven day HRV momentum")
    }


    // MARK: - HRV Day Δ / rateOfChange (Honest #293)
    private var dayDetailHRVROCPoints: [(date: Date, roc: Double)] {
        hrvAnalyzedThroughDay.compactMap { point in
            guard let roc = point.rateOfChange else { return nil }
            return (point.date, roc)
        }
    }

    private var dayDetailHRVLatestROCBand: (label: String, color: Color) {
        guard let roc = dayDetailHRVROCPoints.last?.roc else {
            return ("—", RTColor.secondaryText)
        }
        // HRV: higherIsBetter — Up when ROC > 0.
        let improving = roc > 0
        if abs(roc) < 0.03 { return ("Flat", RTColor.secondaryText) }
        if improving { return ("Up", RTColor.optimal) }
        return ("Down", RTColor.warning)
    }

    private var dayDetailHRVROCYDomain: ClosedRange<Double> {
        let vals = dayDetailHRVROCPoints.map(\.roc)
        let lo = min(vals.min() ?? -0.25, -0.25)
        let hi = max(vals.max() ?? 0.25, 0.25)
        let pad = max((hi - lo) * 0.1, 0.05)
        return (lo - pad)...(hi + pad)
    }

    private var dayDetailHRVDayDeltaStrip: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("HRV Day-over-Day Change")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
                Spacer()
                if let roc = dayDetailHRVROCPoints.last?.roc {
                    let sign = roc >= 0 ? "+" : ""
                    Text(String(format: "%@%.0f%% · %@", sign, roc * 100, dayDetailHRVLatestROCBand.label))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(dayDetailHRVLatestROCBand.color)
                        .monospacedDigit()
                }
            }

            if !dayDetailHRVROCPoints.isEmpty {
                Chart {
                    RuleMark(y: .value("Zero", 0))
                        .foregroundStyle(RTColor.tertiaryText.opacity(0.6))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))

                    ForEach(Array(dayDetailHRVROCPoints.enumerated()), id: \.offset) { _, point in
                        BarMark(
                            x: .value("Date", point.date, unit: .day),
                            y: .value("ROC", point.roc)
                        )
                        .foregroundStyle(
                            point.roc >= 0
                                ? RTColor.optimal.opacity(0.75)
                                : RTColor.warning.opacity(0.75)
                        )
                        .cornerRadius(2)
                    }
                }
                .frame(height: 72)
                .chartYScale(domain: dayDetailHRVROCYDomain)
                .chartXAxis(.hidden)
                .chartYAxis {
                    AxisMarks(position: .leading, values: [dayDetailHRVROCYDomain.lowerBound, 0, dayDetailHRVROCYDomain.upperBound]) { value in
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
                Text("Need ≥2 days for HRV day-over-day change")
                    .font(.caption)
                    .foregroundStyle(RTColor.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(height: 72)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(SurfaceID.dayDetailHRVDayDelta)
        .accessibilityLabel("HRV day over day rate of change")
    }


    // MARK: - Momentum (Honest #277)
    private var dayDetailMomentumPoints: [(date: Date, mom: Double)] {
        sleepAnalyzedThroughDay.compactMap { point in
            guard let mom = point.momentum else { return nil }
            return (point.date, mom)
        }
    }

    private var dayDetailLatestMomentumBand: (label: String, color: Color) {
        guard let mom = dayDetailMomentumPoints.last?.mom else {
            return ("—", RTColor.secondaryText)
        }
        // Sleep: higherIsBetter — rising momentum is improving.
        let improving = mom > 0
        if abs(mom) < 0.05 { return ("Flat", RTColor.secondaryText) }
        if improving { return ("Rising", RTColor.optimal) }
        return ("Fading", RTColor.warning)
    }

    private var dayDetailMomentumYDomain: ClosedRange<Double> {
        let vals = dayDetailMomentumPoints.map(\.mom)
        let lo = min(vals.min() ?? -0.2, -0.2)
        let hi = max(vals.max() ?? 0.2, 0.2)
        let pad = max((hi - lo) * 0.1, 0.05)
        return (lo - pad)...(hi + pad)
    }

    private var dayDetailMomentumStrip: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("7-Day Momentum")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
                Spacer()
                if let mom = dayDetailMomentumPoints.last?.mom {
                    let sign = mom >= 0 ? "+" : ""
                    Text(String(format: "%@%.0f%% · %@", sign, mom * 100, dayDetailLatestMomentumBand.label))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(dayDetailLatestMomentumBand.color)
                        .monospacedDigit()
                }
            }

            if !dayDetailMomentumPoints.isEmpty {
                Chart {
                    RuleMark(y: .value("Zero", 0))
                        .foregroundStyle(RTColor.tertiaryText.opacity(0.6))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))

                    ForEach(Array(dayDetailMomentumPoints.enumerated()), id: \.offset) { _, point in
                        AreaMark(
                            x: .value("Date", point.date, unit: .day),
                            yStart: .value("Zero", 0),
                            yEnd: .value("Mom", point.mom)
                        )
                        .foregroundStyle(
                            point.mom >= 0
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
                .chartYScale(domain: dayDetailMomentumYDomain)
                .chartXAxis(.hidden)
                .chartYAxis {
                    AxisMarks(position: .leading, values: [dayDetailMomentumYDomain.lowerBound, 0, dayDetailMomentumYDomain.upperBound]) { value in
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
        .accessibilityIdentifier(SurfaceID.dayDetailMomentum)
        .accessibilityLabel("Seven day momentum")
    }


    // MARK: - Day Δ / rateOfChange (Honest #278)
    private var dayDetailROCPoints: [(date: Date, roc: Double)] {
        sleepAnalyzedThroughDay.compactMap { point in
            guard let roc = point.rateOfChange else { return nil }
            return (point.date, roc)
        }
    }

    private var dayDetailLatestROCBand: (label: String, color: Color) {
        guard let roc = dayDetailROCPoints.last?.roc else {
            return ("—", RTColor.secondaryText)
        }
        // Sleep: higherIsBetter — Up when ROC > 0.
        let improving = roc > 0
        if abs(roc) < 0.03 { return ("Flat", RTColor.secondaryText) }
        if improving { return ("Up", RTColor.optimal) }
        return ("Down", RTColor.warning)
    }

    private var dayDetailROCYDomain: ClosedRange<Double> {
        let vals = dayDetailROCPoints.map(\.roc)
        let lo = min(vals.min() ?? -0.25, -0.25)
        let hi = max(vals.max() ?? 0.25, 0.25)
        let pad = max((hi - lo) * 0.1, 0.05)
        return (lo - pad)...(hi + pad)
    }

    private var dayDetailDayDeltaStrip: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Day-over-Day Change")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
                Spacer()
                if let roc = dayDetailROCPoints.last?.roc {
                    let sign = roc >= 0 ? "+" : ""
                    Text(String(format: "%@%.0f%% · %@", sign, roc * 100, dayDetailLatestROCBand.label))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(dayDetailLatestROCBand.color)
                        .monospacedDigit()
                }
            }

            if !dayDetailROCPoints.isEmpty {
                Chart {
                    RuleMark(y: .value("Zero", 0))
                        .foregroundStyle(RTColor.tertiaryText.opacity(0.6))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))

                    ForEach(Array(dayDetailROCPoints.enumerated()), id: \.offset) { _, point in
                        BarMark(
                            x: .value("Date", point.date, unit: .day),
                            y: .value("ROC", point.roc)
                        )
                        .foregroundStyle(
                            point.roc >= 0
                                ? RTColor.optimal.opacity(0.75)
                                : RTColor.warning.opacity(0.75)
                        )
                        .cornerRadius(2)
                    }
                }
                .frame(height: 72)
                .chartYScale(domain: dayDetailROCYDomain)
                .chartXAxis(.hidden)
                .chartYAxis {
                    AxisMarks(position: .leading, values: [dayDetailROCYDomain.lowerBound, 0, dayDetailROCYDomain.upperBound]) { value in
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
        .accessibilityIdentifier(SurfaceID.dayDetailDayDelta)
        .accessibilityLabel("Day over day rate of change")
    }

    // MARK: - Statistics CV% (Honest #275)
    private func dayDetailStatsCVSection(cv: Double) -> some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Statistics")
                    .font(RTFont.headline)
                    .foregroundColor(RTColor.primaryText)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    StatItem(label: "Volatility", value: "\(Int(cv * 100))%", unit: "CV")
                        .accessibilityIdentifier(SurfaceID.dayDetailStatsCV)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(SurfaceID.dayDetailStatsCV)
        .accessibilityLabel("Volatility coefficient of variation")
    }



    // MARK: - HRV Statistics CV% (Honest #285)
    private func dayDetailHRVStatsCVSection(cv: Double) -> some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("HRV Statistics")
                    .font(RTFont.headline)
                    .foregroundColor(RTColor.primaryText)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    StatItem(label: "Volatility", value: "\(Int(cv * 100))%", unit: "CV")
                        .accessibilityIdentifier(SurfaceID.dayDetailHRVStatsCV)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(SurfaceID.dayDetailHRVStatsCV)
        .accessibilityLabel("HRV volatility coefficient of variation")
    }



    // MARK: - RHR Statistics CV% (Honest #300)
    private func dayDetailRHRStatsCVSection(cv: Double) -> some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("RHR Statistics")
                    .font(RTFont.headline)
                    .foregroundColor(RTColor.primaryText)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    StatItem(label: "Volatility", value: "\(Int(cv * 100))%", unit: "CV")
                        .accessibilityIdentifier(SurfaceID.dayDetailRHRStatsCV)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(SurfaceID.dayDetailRHRStatsCV)
        .accessibilityLabel("RHR volatility coefficient of variation")
    }


    // MARK: - Strain Statistics CV% (Honest #316)
    private func dayDetailStrainStatsCVSection(cv: Double) -> some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Strain Statistics")
                    .font(RTFont.headline)
                    .foregroundColor(RTColor.primaryText)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    StatItem(label: "Volatility", value: "\(Int(cv * 100))%", unit: "CV")
                        .accessibilityIdentifier(SurfaceID.dayDetailStrainStatsCV)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(SurfaceID.dayDetailStrainStatsCV)
        .accessibilityLabel("Strain volatility coefficient of variation")
    }

    // MARK: - SpO2 Statistics CV% (Honest #331)
    private func dayDetailSpO2StatsCVSection(cv: Double) -> some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("SpO2 Statistics")
                    .font(RTFont.headline)
                    .foregroundColor(RTColor.primaryText)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    StatItem(label: "Volatility", value: "\(Int(cv * 100))%", unit: "CV")
                        .accessibilityIdentifier(SurfaceID.dayDetailSpO2StatsCV)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(SurfaceID.dayDetailSpO2StatsCV)
        .accessibilityLabel("SpO2 volatility coefficient of variation")
    }


    // MARK: - % vs Baseline (Honest #280)
    private func dayDetailPercentDeviationCallout(_ label: String) -> some View {
        let improving: Bool = {
            guard let a = sleepDayAnalyzed else { return true }
            // Sleep: higherIsBetter — above baseline is improving.
            return a.percentDeviation >= 0
        }()
        let tint = abs(sleepDayAnalyzed?.percentDeviation ?? 0) < 0.05
            ? RTColor.secondaryText
            : (improving ? RTColor.optimal : RTColor.warning)
        return HStack(spacing: 8) {
            Image(systemName: "percent")
                .font(.caption.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 26, height: 26)
                .background(tint.opacity(0.14))
                .clipShape(Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(tint)
                Text("Sleep vs series baseline")
                    .font(.caption2)
                    .foregroundStyle(RTColor.secondaryText)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(tint.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(SurfaceID.dayDetailPercentDeviation)
        .accessibilityLabel(label)
    }

    // MARK: - Classify Trend (Honest #274)
    private func dayDetailClassifyTrendCallout(_ strength: TrendAnalysisEngine.TrendStrength) -> some View {
        let r2 = sleepAnalyzedThroughDay.last?.trendRSquared
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
        .accessibilityIdentifier(SurfaceID.dayDetailTrendStrength)
        .accessibilityLabel("Trend strength " + strength.rawValue)
    }


    // MARK: - HRV % vs Baseline (Honest #284)
    private func dayDetailHRVPercentDeviationCallout(_ label: String) -> some View {
        let improving: Bool = {
            guard let a = hrvDayAnalyzed else { return true }
            // HRV: higherIsBetter — above baseline is improving.
            return a.percentDeviation >= 0
        }()
        let tint = abs(hrvDayAnalyzed?.percentDeviation ?? 0) < 0.05
            ? RTColor.secondaryText
            : (improving ? RTColor.optimal : RTColor.warning)
        return HStack(spacing: 8) {
            Image(systemName: "percent")
                .font(.caption.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 26, height: 26)
                .background(tint.opacity(0.14))
                .clipShape(Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("HRV · " + label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(tint)
                Text("HRV vs series baseline")
                    .font(.caption2)
                    .foregroundStyle(RTColor.secondaryText)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(tint.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(SurfaceID.dayDetailHRVPercentDeviation)
        .accessibilityLabel("HRV " + label)
    }

    // MARK: - HRV Classify Trend (Honest #283)
    private func dayDetailHRVClassifyTrendCallout(_ strength: TrendAnalysisEngine.TrendStrength) -> some View {
        let r2 = hrvAnalyzedThroughDay.last?.trendRSquared
        return HStack(spacing: 8) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.caption.weight(.semibold))
                .foregroundStyle(strength.trendColor)
                .frame(width: 26, height: 26)
                .background(strength.trendColor.opacity(0.14))
                .clipShape(Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("HRV · " + strength.rawValue)
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
        .accessibilityIdentifier(SurfaceID.dayDetailHRVTrendStrength)
        .accessibilityLabel("HRV trend strength " + strength.rawValue)
    }


    // MARK: - RHR Classify Trend (Honest #298)
    private func dayDetailRHRClassifyTrendCallout(_ strength: TrendAnalysisEngine.TrendStrength) -> some View {
        let r2 = rhrAnalyzedThroughDay.last?.trendRSquared
        return HStack(spacing: 8) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.caption.weight(.semibold))
                .foregroundStyle(strength.trendColor)
                .frame(width: 26, height: 26)
                .background(strength.trendColor.opacity(0.14))
                .clipShape(Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("RHR · " + strength.rawValue)
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
        .accessibilityIdentifier(SurfaceID.dayDetailRHRTrendStrength)
        .accessibilityLabel("RHR trend strength " + strength.rawValue)
    }


    // MARK: - Strain Classify Trend (Honest #314)
    private func dayDetailStrainClassifyTrendCallout(_ strength: TrendAnalysisEngine.TrendStrength) -> some View {
        let r2 = strainAnalyzedThroughDay.last?.trendRSquared
        return HStack(spacing: 8) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.caption.weight(.semibold))
                .foregroundStyle(strength.trendColor)
                .frame(width: 26, height: 26)
                .background(strength.trendColor.opacity(0.14))
                .clipShape(Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("Strain · " + strength.rawValue)
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
        .accessibilityIdentifier(SurfaceID.dayDetailStrainTrendStrength)
        .accessibilityLabel("Strain trend strength " + strength.rawValue)
    }

    // MARK: - SpO2 Classify Trend (Honest #329)
    private func dayDetailSpO2ClassifyTrendCallout(_ strength: TrendAnalysisEngine.TrendStrength) -> some View {
        let r2 = spo2AnalyzedThroughDay.last?.trendRSquared
        return HStack(spacing: 8) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.caption.weight(.semibold))
                .foregroundStyle(strength.trendColor)
                .frame(width: 26, height: 26)
                .background(strength.trendColor.opacity(0.14))
                .clipShape(Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("SpO2 · " + strength.rawValue)
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
        .accessibilityIdentifier(SurfaceID.dayDetailSpO2TrendStrength)
        .accessibilityLabel("SpO2 trend strength " + strength.rawValue)
    }

    // MARK: - SpO2 % vs Baseline (Honest #330)
    private func dayDetailSpO2PercentDeviationCallout(_ label: String) -> some View {
        let improving: Bool = {
            guard let a = spo2DayAnalyzed else { return true }
            // SpO2/bloodOxygen: higherIsBetter — above baseline is improving.
            return a.percentDeviation >= 0
        }()
        let tint = abs(spo2DayAnalyzed?.percentDeviation ?? 0) < 0.05
            ? RTColor.secondaryText
            : (improving ? RTColor.optimal : RTColor.warning)
        return HStack(spacing: 8) {
            Image(systemName: "percent")
                .font(.caption.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 26, height: 26)
                .background(tint.opacity(0.14))
                .clipShape(Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("SpO2 · " + label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(tint)
                Text("SpO2 vs series baseline")
                    .font(.caption2)
                    .foregroundStyle(RTColor.secondaryText)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(tint.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(SurfaceID.dayDetailSpO2PercentDeviation)
        .accessibilityLabel("SpO2 " + label)
    }


    // MARK: - Strain % vs Baseline (Honest #315)
    private func dayDetailStrainPercentDeviationCallout(_ label: String) -> some View {
        let improving: Bool = {
            guard let a = strainDayAnalyzed else { return true }
            // Strain/activeCalories: higherIsBetter — above baseline is improving.
            return a.percentDeviation >= 0
        }()
        let tint = abs(strainDayAnalyzed?.percentDeviation ?? 0) < 0.05
            ? RTColor.secondaryText
            : (improving ? RTColor.optimal : RTColor.warning)
        return HStack(spacing: 8) {
            Image(systemName: "percent")
                .font(.caption.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 26, height: 26)
                .background(tint.opacity(0.14))
                .clipShape(Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("Strain · " + label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(tint)
                Text("Strain vs series baseline")
                    .font(.caption2)
                    .foregroundStyle(RTColor.secondaryText)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(tint.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(SurfaceID.dayDetailStrainPercentDeviation)
        .accessibilityLabel("Strain " + label)
    }


    // MARK: - RHR % vs Baseline (Honest #299)
    private func dayDetailRHRPercentDeviationCallout(_ label: String) -> some View {
        let improving: Bool = {
            guard let a = rhrDayAnalyzed else { return true }
            // RHR: lowerIsBetter — below baseline is improving.
            return a.percentDeviation <= 0
        }()
        let tint = abs(rhrDayAnalyzed?.percentDeviation ?? 0) < 0.05
            ? RTColor.secondaryText
            : (improving ? RTColor.optimal : RTColor.warning)
        return HStack(spacing: 8) {
            Image(systemName: "percent")
                .font(.caption.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 26, height: 26)
                .background(tint.opacity(0.14))
                .clipShape(Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("RHR · " + label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(tint)
                Text("RHR vs series baseline")
                    .font(.caption2)
                    .foregroundStyle(RTColor.secondaryText)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(tint.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(SurfaceID.dayDetailRHRPercentDeviation)
        .accessibilityLabel("RHR " + label)
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


    // MARK: - HRV Outlier Highlights (Honest #286)
    /// Elevate unused isOutlier on HRV via OutlierCallout list (up to 3) — Sleep #272 dual.
    @ViewBuilder
    private var dayDetailHRVOutlierSection: some View {
        let outliers = hrvAnalyzedThroughDay.filter(\.isOutlier)
        if !outliers.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("HRV Highlights")
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
                            value: "\(Int(point.rawValue.rounded())) ms",
                            date: dateStr,
                            deviation: deviationStr
                        )
                    }
                }
                .accessibilityIdentifier(SurfaceID.dayDetailHRVOutlierList)
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(SurfaceID.dayDetailHRVOutlierList)
            .accessibilityLabel("HRV outlier highlights")
        }
    }


    // MARK: - RHR Outlier Highlights (Honest #301)
    /// Elevate unused isOutlier on RHR via OutlierCallout list (up to 3) — Sleep #272 / HRV #286 dual.
    @ViewBuilder
    private var dayDetailRHROutlierSection: some View {
        let outliers = rhrAnalyzedThroughDay.filter(\.isOutlier)
        if !outliers.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("RHR Highlights")
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
                            value: "\(Int(point.rawValue.rounded())) bpm",
                            date: dateStr,
                            deviation: deviationStr
                        )
                    }
                }
                .accessibilityIdentifier(SurfaceID.dayDetailRHROutlierList)
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(SurfaceID.dayDetailRHROutlierList)
            .accessibilityLabel("RHR outlier highlights")
        }
    }

    // MARK: - Strain Outlier Highlights (Honest #317)
    /// Elevate unused isOutlier on Strain via OutlierCallout list (up to 3) — Sleep #272 / HRV #286 / RHR #301 dual.
    @ViewBuilder
    private var dayDetailStrainOutlierSection: some View {
        let outliers = strainAnalyzedThroughDay.filter(\.isOutlier)
        if !outliers.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Strain Highlights")
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
                            value: "\(Int(point.rawValue.rounded())) cal",
                            date: dateStr,
                            deviation: deviationStr
                        )
                    }
                }
                .accessibilityIdentifier(SurfaceID.dayDetailStrainOutlierList)
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(SurfaceID.dayDetailStrainOutlierList)
            .accessibilityLabel("Strain outlier highlights")
        }
    }

    // MARK: - SpO2 Outlier Highlights (Honest #332)
    /// Elevate unused isOutlier on SpO2 via OutlierCallout list (up to 3) — Sleep #272 / Strain #317 dual.
    @ViewBuilder
    private var dayDetailSpO2OutlierSection: some View {
        let outliers = spo2AnalyzedThroughDay.filter(\.isOutlier)
        if !outliers.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("SpO2 Highlights")
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
                            value: "\(Int(point.rawValue.rounded()))%",
                            date: dateStr,
                            deviation: deviationStr
                        )
                    }
                }
                .accessibilityIdentifier(SurfaceID.dayDetailSpO2OutlierList)
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(SurfaceID.dayDetailSpO2OutlierList)
            .accessibilityLabel("SpO2 outlier highlights")
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

                        // Honest #280: % vs baseline callout (percentDeviation / scrub parity).
                        if let label = sleepPercentDeviationLabel {
                            dayDetailPercentDeviationCallout(label)
                        }

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

                            // Honest #279/#281: MA7 + MA14 + EMA overlays (always-on; no chrome toggles).
                            ForEach(Array(sleepOverlaySeries.enumerated()), id: \.offset) { _, point in
                                if let ma7 = point.ma7 {
                                    LineMark(
                                        x: .value("Date", point.date, unit: .day),
                                        y: .value("MA7", ma7)
                                    )
                                    .foregroundStyle(RTColor.primaryText.opacity(0.75))
                                    .lineStyle(StrokeStyle(lineWidth: 1.5))
                                    .interpolationMethod(.catmullRom)
                                }
                                if let ma14 = point.ma14 {
                                    LineMark(
                                        x: .value("Date", point.date, unit: .day),
                                        y: .value("MA14", ma14)
                                    )
                                    .foregroundStyle(RTColor.recovery.opacity(0.9))
                                    .lineStyle(StrokeStyle(lineWidth: 1.75, dash: [8, 4]))
                                    .interpolationMethod(.catmullRom)
                                }
                                if let ema = point.ema {
                                    LineMark(
                                        x: .value("Date", point.date, unit: .day),
                                        y: .value("EMA7", ema)
                                    )
                                    .foregroundStyle(RTColor.hrv.opacity(0.85))
                                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [6, 3]))
                                    .interpolationMethod(.catmullRom)
                                }
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

                        // Honest #279/#281: MA7 + MA14 + EMA legend (always-on; no chrome toggles).
                        if sleepOverlaySeries.contains(where: { $0.ma7 != nil || $0.ma14 != nil || $0.ema != nil }) {
                            HStack(spacing: 16) {
                                if sleepOverlaySeries.contains(where: { $0.ma7 != nil }) {
                                    HStack(spacing: 6) {
                                        Capsule()
                                            .fill(RTColor.primaryText.opacity(0.75))
                                            .frame(width: 18, height: 2)
                                        Text("MA7")
                                            .font(.caption2)
                                            .foregroundStyle(RTColor.secondaryText)
                                            .accessibilityIdentifier(SurfaceID.dayDetailMA7)
                                    }
                                }
                                if sleepOverlaySeries.contains(where: { $0.ma14 != nil }) {
                                    HStack(spacing: 6) {
                                        Capsule()
                                            .stroke(RTColor.recovery.opacity(0.9), style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                                            .frame(width: 18, height: 2)
                                        Text("MA14")
                                            .font(.caption2)
                                            .foregroundStyle(RTColor.secondaryText)
                                            .accessibilityIdentifier(SurfaceID.dayDetailMA14)
                                    }
                                }
                                if sleepOverlaySeries.contains(where: { $0.ema != nil }) {
                                    HStack(spacing: 6) {
                                        Capsule()
                                            .stroke(RTColor.hrv.opacity(0.85), style: StrokeStyle(lineWidth: 2, dash: [6, 3]))
                                            .frame(width: 18, height: 2)
                                        Text("EMA")
                                            .font(.caption2)
                                            .foregroundStyle(RTColor.secondaryText)
                                            .accessibilityIdentifier(SurfaceID.dayDetailEMA)
                                    }
                                }
                                Spacer(minLength: 0)
                            }
                            .accessibilityElement(children: .contain)
                            .accessibilityLabel("MA7 MA14 and EMA overlays")
                        }
                    }
                }
                
                // HRV trend
                NativeCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("HRV Trend")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(RTColor.primaryText)
                        
                        Chart {
                            // Honest #287: ±2σ baseline bands on HRV (Sleep #273 dual).
                            if let stats = hrvBaselineStats {
                                let cal = Calendar.current
                                let low = stats.baseline - 2 * stats.stdDev
                                let high = stats.baseline + 2 * stats.stdDev
                                ForEach(sevenDayWindow) { day in
                                    let endDate = cal.date(byAdding: .day, value: 1, to: day.date) ?? day.date
                                    let z = TrendAnalysisEngine.zScore(
                                        value: day.hrv,
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

                            // Honest #288/#289: MA7 + MA14 + EMA overlays on HRV Trend (always-on).
                            ForEach(Array(hrvOverlaySeries.enumerated()), id: \.offset) { _, point in
                                if let ma7 = point.ma7 {
                                    LineMark(
                                        x: .value("Date", point.date, unit: .day),
                                        y: .value("MA7", ma7)
                                    )
                                    .foregroundStyle(RTColor.primaryText.opacity(0.75))
                                    .lineStyle(StrokeStyle(lineWidth: 1.5))
                                    .interpolationMethod(.catmullRom)
                                }
                                if let ma14 = point.ma14 {
                                    LineMark(
                                        x: .value("Date", point.date, unit: .day),
                                        y: .value("MA14", ma14)
                                    )
                                    .foregroundStyle(RTColor.recovery.opacity(0.9))
                                    .lineStyle(StrokeStyle(lineWidth: 1.75, dash: [8, 4]))
                                    .interpolationMethod(.catmullRom)
                                }
                                if let ema = point.ema {
                                    LineMark(
                                        x: .value("Date", point.date, unit: .day),
                                        y: .value("EMA7", ema)
                                    )
                                    .foregroundStyle(RTColor.sleep.opacity(0.85))
                                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [6, 3]))
                                    .interpolationMethod(.catmullRom)
                                }
                            }
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

                        // Honest #287: Baseline ±2σ legend on HRV Trend (Sleep #273 dual).
                        if hrvBaselineStats != nil {
                            HStack(spacing: 6) {
                                Capsule()
                                    .stroke(RTColor.tertiaryText, style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                                    .frame(width: 18, height: 2)
                                Text("Baseline")
                                    .font(.caption2)
                                    .foregroundStyle(RTColor.secondaryText)
                                    .accessibilityIdentifier(SurfaceID.dayDetailHRVBaselineBands)
                                Text("±2σ")
                                    .font(.caption2)
                                    .foregroundStyle(RTColor.tertiaryText)
                                Spacer(minLength: 0)
                            }
                            .accessibilityElement(children: .contain)
                            .accessibilityIdentifier(SurfaceID.dayDetailHRVBaselineBands)
                            .accessibilityLabel("HRV baseline bands plus or minus two sigma")
                        }

                        // Honest #288/#289: MA7 + MA14 + EMA legend on HRV Trend (always-on).
                        if hrvOverlaySeries.contains(where: { $0.ma7 != nil || $0.ma14 != nil || $0.ema != nil }) {
                            HStack(spacing: 16) {
                                if hrvOverlaySeries.contains(where: { $0.ma7 != nil }) {
                                    HStack(spacing: 6) {
                                        Capsule()
                                            .fill(RTColor.primaryText.opacity(0.75))
                                            .frame(width: 18, height: 2)
                                        Text("MA7")
                                            .font(.caption2)
                                            .foregroundStyle(RTColor.secondaryText)
                                            .accessibilityIdentifier(SurfaceID.dayDetailHRVMA7)
                                    }
                                }
                                if hrvOverlaySeries.contains(where: { $0.ma14 != nil }) {
                                    HStack(spacing: 6) {
                                        Capsule()
                                            .stroke(RTColor.recovery.opacity(0.9), style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                                            .frame(width: 18, height: 2)
                                        Text("MA14")
                                            .font(.caption2)
                                            .foregroundStyle(RTColor.secondaryText)
                                            .accessibilityIdentifier(SurfaceID.dayDetailHRVMA14)
                                    }
                                }
                                if hrvOverlaySeries.contains(where: { $0.ema != nil }) {
                                    HStack(spacing: 6) {
                                        Capsule()
                                            .stroke(RTColor.sleep.opacity(0.85), style: StrokeStyle(lineWidth: 2, dash: [6, 3]))
                                            .frame(width: 18, height: 2)
                                        Text("EMA")
                                            .font(.caption2)
                                            .foregroundStyle(RTColor.secondaryText)
                                            .accessibilityIdentifier(SurfaceID.dayDetailHRVEMA)
                                    }
                                }
                                Spacer(minLength: 0)
                            }
                            .accessibilityElement(children: .contain)
                            .accessibilityLabel("HRV MA7 MA14 and EMA overlays")
                        }
                    }
                }
                
                // RHR trend
                NativeCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Resting HR Trend")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(RTColor.primaryText)
                        
                        Chart {
                            // Honest #302: ±2σ baseline bands on RHR (Sleep #273 / HRV #287 dual).
                            if let stats = rhrBaselineStats {
                                let cal = Calendar.current
                                let low = stats.baseline - 2 * stats.stdDev
                                let high = stats.baseline + 2 * stats.stdDev
                                ForEach(sevenDayWindow) { day in
                                    let endDate = cal.date(byAdding: .day, value: 1, to: day.date) ?? day.date
                                    let z = TrendAnalysisEngine.zScore(
                                        value: day.restingHeartRate,
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

                            // Honest #303/#304: MA7 + MA14 + EMA overlays on Resting HR Trend (always-on).
                            ForEach(Array(rhrOverlaySeries.enumerated()), id: \.offset) { _, point in
                                if let ma7 = point.ma7 {
                                    LineMark(
                                        x: .value("Date", point.date, unit: .day),
                                        y: .value("MA7", ma7)
                                    )
                                    .foregroundStyle(RTColor.primaryText.opacity(0.75))
                                    .lineStyle(StrokeStyle(lineWidth: 1.5))
                                    .interpolationMethod(.catmullRom)
                                }
                                if let ma14 = point.ma14 {
                                    LineMark(
                                        x: .value("Date", point.date, unit: .day),
                                        y: .value("MA14", ma14)
                                    )
                                    .foregroundStyle(RTColor.recovery.opacity(0.9))
                                    .lineStyle(StrokeStyle(lineWidth: 1.75, dash: [8, 4]))
                                    .interpolationMethod(.catmullRom)
                                }
                                if let ema = point.ema {
                                    LineMark(
                                        x: .value("Date", point.date, unit: .day),
                                        y: .value("EMA7", ema)
                                    )
                                    .foregroundStyle(RTColor.sleep.opacity(0.85))
                                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [6, 3]))
                                    .interpolationMethod(.catmullRom)
                                }
                            }
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

                        // Honest #302: Baseline ±2σ legend on Resting HR Trend (Sleep #273 / HRV #287 dual).
                        if rhrBaselineStats != nil {
                            HStack(spacing: 6) {
                                Capsule()
                                    .stroke(RTColor.tertiaryText, style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                                    .frame(width: 18, height: 2)
                                Text("Baseline")
                                    .font(.caption2)
                                    .foregroundStyle(RTColor.secondaryText)
                                    .accessibilityIdentifier(SurfaceID.dayDetailRHRBaselineBands)
                                Text("±2σ")
                                    .font(.caption2)
                                    .foregroundStyle(RTColor.tertiaryText)
                                Spacer(minLength: 0)
                            }
                            .accessibilityElement(children: .contain)
                            .accessibilityIdentifier(SurfaceID.dayDetailRHRBaselineBands)
                            .accessibilityLabel("RHR baseline bands plus or minus two sigma")
                        }

                        // Honest #303/#304: MA7 + MA14 + EMA legend on Resting HR Trend (always-on).
                        if rhrOverlaySeries.contains(where: { $0.ma7 != nil || $0.ma14 != nil || $0.ema != nil }) {
                            HStack(spacing: 16) {
                                if rhrOverlaySeries.contains(where: { $0.ma7 != nil }) {
                                    HStack(spacing: 6) {
                                        Capsule()
                                            .fill(RTColor.primaryText.opacity(0.75))
                                            .frame(width: 18, height: 2)
                                        Text("MA7")
                                            .font(.caption2)
                                            .foregroundStyle(RTColor.secondaryText)
                                            .accessibilityIdentifier(SurfaceID.dayDetailRHRMA7)
                                    }
                                }
                                if rhrOverlaySeries.contains(where: { $0.ma14 != nil }) {
                                    HStack(spacing: 6) {
                                        Capsule()
                                            .stroke(RTColor.recovery.opacity(0.9), style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                                            .frame(width: 18, height: 2)
                                        Text("MA14")
                                            .font(.caption2)
                                            .foregroundStyle(RTColor.secondaryText)
                                            .accessibilityIdentifier(SurfaceID.dayDetailRHRMA14)
                                    }
                                }
                                if rhrOverlaySeries.contains(where: { $0.ema != nil }) {
                                    HStack(spacing: 6) {
                                        Capsule()
                                            .stroke(RTColor.sleep.opacity(0.85), style: StrokeStyle(lineWidth: 2, dash: [6, 3]))
                                            .frame(width: 18, height: 2)
                                        Text("EMA")
                                            .font(.caption2)
                                            .foregroundStyle(RTColor.secondaryText)
                                            .accessibilityIdentifier(SurfaceID.dayDetailRHREMA)
                                    }
                                }
                                Spacer(minLength: 0)
                            }
                            .accessibilityElement(children: .contain)
                            .accessibilityLabel("RHR MA7 MA14 and EMA overlays")
                        }
                    }
                }

                // Strain / Active Calories trend (Honest #318 host for baseline bands; MA overlays → #319+)
                NativeCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Active Calories Trend")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(RTColor.primaryText)

                        Chart {
                            // Honest #318: ±2σ baseline bands on Strain (Sleep #273 / HRV #287 / RHR #302 dual).
                            if let stats = strainBaselineStats {
                                let cal = Calendar.current
                                let low = stats.baseline - 2 * stats.stdDev
                                let high = stats.baseline + 2 * stats.stdDev
                                ForEach(sevenDayWindow) { day in
                                    let endDate = cal.date(byAdding: .day, value: 1, to: day.date) ?? day.date
                                    let z = TrendAnalysisEngine.zScore(
                                        value: day.activeCalories,
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
                                LineMark(
                                    x: .value("Date", day.date, unit: .day),
                                    y: .value("Cals", day.activeCalories)
                                )
                                .foregroundStyle(RTColor.caution)
                                .interpolationMethod(.catmullRom)
                                .lineStyle(StrokeStyle(lineWidth: 2.5))

                                PointMark(
                                    x: .value("Date", day.date, unit: .day),
                                    y: .value("Cals", day.activeCalories)
                                )
                                .foregroundStyle(day.id == data.id ? RTColor.caution : RTColor.caution.opacity(0.4))
                                .symbolSize(day.id == data.id ? 80 : 40)
                            }

                            // Honest #319/#320: MA7 + MA14 + EMA overlays on Active Calories Trend (always-on).
                            ForEach(Array(strainOverlaySeries.enumerated()), id: \.offset) { _, point in
                                if let ma7 = point.ma7 {
                                    LineMark(
                                        x: .value("Date", point.date, unit: .day),
                                        y: .value("MA7", ma7)
                                    )
                                    .foregroundStyle(RTColor.primaryText.opacity(0.75))
                                    .lineStyle(StrokeStyle(lineWidth: 1.5))
                                    .interpolationMethod(.catmullRom)
                                }
                                if let ma14 = point.ma14 {
                                    LineMark(
                                        x: .value("Date", point.date, unit: .day),
                                        y: .value("MA14", ma14)
                                    )
                                    .foregroundStyle(RTColor.recovery.opacity(0.9))
                                    .lineStyle(StrokeStyle(lineWidth: 1.75, dash: [8, 4]))
                                    .interpolationMethod(.catmullRom)
                                }
                                if let ema = point.ema {
                                    LineMark(
                                        x: .value("Date", point.date, unit: .day),
                                        y: .value("EMA7", ema)
                                    )
                                    .foregroundStyle(RTColor.sleep.opacity(0.85))
                                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [6, 3]))
                                    .interpolationMethod(.catmullRom)
                                }
                            }
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

                        // Honest #318: Baseline ±2σ legend on Active Calories Trend.
                        if strainBaselineStats != nil {
                            HStack(spacing: 6) {
                                Capsule()
                                    .stroke(RTColor.tertiaryText, style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                                    .frame(width: 18, height: 2)
                                Text("Baseline")
                                    .font(.caption2)
                                    .foregroundStyle(RTColor.secondaryText)
                                    .accessibilityIdentifier(SurfaceID.dayDetailStrainBaselineBands)
                                Text("±2σ")
                                    .font(.caption2)
                                    .foregroundStyle(RTColor.tertiaryText)
                                Spacer(minLength: 0)
                            }
                            .accessibilityElement(children: .contain)
                            .accessibilityIdentifier(SurfaceID.dayDetailStrainBaselineBands)
                            .accessibilityLabel("Strain baseline bands plus or minus two sigma")
                        }

                        // Honest #319/#320: MA7 + MA14 + EMA legend on Active Calories Trend (always-on).
                        if strainOverlaySeries.contains(where: { $0.ma7 != nil || $0.ma14 != nil || $0.ema != nil }) {
                            HStack(spacing: 16) {
                                if strainOverlaySeries.contains(where: { $0.ma7 != nil }) {
                                    HStack(spacing: 6) {
                                        Capsule()
                                            .fill(RTColor.primaryText.opacity(0.75))
                                            .frame(width: 18, height: 2)
                                        Text("MA7")
                                            .font(.caption2)
                                            .foregroundStyle(RTColor.secondaryText)
                                            .accessibilityIdentifier(SurfaceID.dayDetailStrainMA7)
                                    }
                                }
                                if strainOverlaySeries.contains(where: { $0.ma14 != nil }) {
                                    HStack(spacing: 6) {
                                        Capsule()
                                            .stroke(RTColor.recovery.opacity(0.9), style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                                            .frame(width: 18, height: 2)
                                        Text("MA14")
                                            .font(.caption2)
                                            .foregroundStyle(RTColor.secondaryText)
                                            .accessibilityIdentifier(SurfaceID.dayDetailStrainMA14)
                                    }
                                }
                                if strainOverlaySeries.contains(where: { $0.ema != nil }) {
                                    HStack(spacing: 6) {
                                        Capsule()
                                            .stroke(RTColor.sleep.opacity(0.85), style: StrokeStyle(lineWidth: 2, dash: [6, 3]))
                                            .frame(width: 18, height: 2)
                                        Text("EMA")
                                            .font(.caption2)
                                            .foregroundStyle(RTColor.secondaryText)
                                            .accessibilityIdentifier(SurfaceID.dayDetailStrainEMA)
                                    }
                                }
                                Spacer(minLength: 0)
                            }
                            .accessibilityElement(children: .contain)
                            .accessibilityLabel("Strain MA7 MA14 and EMA overlays")
                        }
                    }
                }

                // Blood Oxygen trend (Honest #333 host for baseline bands; MA overlays → later)
                if !spo2SevenDayPoints.isEmpty {
                    NativeCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Blood Oxygen Trend")
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(RTColor.primaryText)

                            Chart {
                                // Honest #333: ±2σ baseline bands on SpO2 (Sleep #273 / Strain #318 dual).
                                if let stats = spo2BaselineStats {
                                    let cal = Calendar.current
                                    let low = stats.baseline - 2 * stats.stdDev
                                    let high = stats.baseline + 2 * stats.stdDev
                                    ForEach(Array(spo2SevenDayPoints.enumerated()), id: \.offset) { _, point in
                                        let endDate = cal.date(byAdding: .day, value: 1, to: point.date) ?? point.date
                                        let z = TrendAnalysisEngine.zScore(
                                            value: point.value,
                                            baseline: stats.baseline,
                                            stdDev: stats.stdDev
                                        )
                                        RectangleMark(
                                            xStart: .value("Date", point.date),
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

                                ForEach(Array(spo2SevenDayPoints.enumerated()), id: \.offset) { _, point in
                                    LineMark(
                                        x: .value("Date", point.date, unit: .day),
                                        y: .value("SpO2", point.value)
                                    )
                                    .foregroundStyle(RTColor.optimal)
                                    .interpolationMethod(.catmullRom)
                                    .lineStyle(StrokeStyle(lineWidth: 2.5))

                                    PointMark(
                                        x: .value("Date", point.date, unit: .day),
                                        y: .value("SpO2", point.value)
                                    )
                                    .foregroundStyle(point.isSelected ? RTColor.optimal : RTColor.optimal.opacity(0.4))
                                    .symbolSize(point.isSelected ? 80 : 40)
                                }

                                // Honest #334: MA7 overlay on Blood Oxygen Trend (always-on; Sleep #281 / Strain #319 dual).
                                ForEach(Array(spo2OverlaySeries.enumerated()), id: \.offset) { _, point in
                                    if let ma7 = point.ma7 {
                                        LineMark(
                                            x: .value("Date", point.date, unit: .day),
                                            y: .value("MA7", ma7)
                                        )
                                        .foregroundStyle(RTColor.primaryText.opacity(0.75))
                                        .lineStyle(StrokeStyle(lineWidth: 1.5))
                                        .interpolationMethod(.catmullRom)
                                    }
                                }
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

                            // Honest #333: Baseline ±2σ legend on Blood Oxygen Trend.
                            if spo2BaselineStats != nil {
                                HStack(spacing: 6) {
                                    Capsule()
                                        .stroke(RTColor.tertiaryText, style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                                        .frame(width: 18, height: 2)
                                    Text("Baseline")
                                        .font(.caption2)
                                        .foregroundStyle(RTColor.secondaryText)
                                        .accessibilityIdentifier(SurfaceID.dayDetailSpO2BaselineBands)
                                    Text("±2σ")
                                        .font(.caption2)
                                        .foregroundStyle(RTColor.tertiaryText)
                                    Spacer(minLength: 0)
                                }
                                .accessibilityElement(children: .contain)
                                .accessibilityIdentifier(SurfaceID.dayDetailSpO2BaselineBands)
                                .accessibilityLabel("SpO2 baseline bands plus or minus two sigma")
                            }

                            // Honest #334: MA7 legend on Blood Oxygen Trend (always-on).
                            if spo2OverlaySeries.contains(where: { $0.ma7 != nil }) {
                                HStack(spacing: 16) {
                                    HStack(spacing: 6) {
                                        Capsule()
                                            .fill(RTColor.primaryText.opacity(0.75))
                                            .frame(width: 18, height: 2)
                                        Text("MA7")
                                            .font(.caption2)
                                            .foregroundStyle(RTColor.secondaryText)
                                            .accessibilityIdentifier(SurfaceID.dayDetailSpO2MA7)
                                    }
                                    Spacer(minLength: 0)
                                }
                                .accessibilityElement(children: .contain)
                                .accessibilityLabel("SpO2 MA7 overlay")
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
