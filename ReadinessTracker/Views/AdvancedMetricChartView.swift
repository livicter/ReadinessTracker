import SwiftUI
import Charts

/// Advanced chart view showing real data science analysis on user's actual health data.
/// Apple Health–style drag scrubbing: RuleMark + solid-surface tooltip callout.
struct AdvancedMetricChartView: View {
    let metric: MetricType
    let analyzedData: [AnalyzedDataPoint]
    let showBaselineBands: Bool
    let showMovingAverage: Bool
    let showOutliers: Bool
    var showVolatility: Bool = true  // Honest #240: rolling CV strip
    var showMomentum: Bool = true  // Honest #241: momentum strip
    var showEMA: Bool = true  // Honest #242: EMA line on main chart
    var showMA14: Bool = true  // Honest #244: SMA-14 line on main chart
    var showRateOfChange: Bool = true  // Honest #243: day-over-day ROC strip
    
    @State private var selectedPoint: AnalyzedDataPoint?
    @State private var lastHapticID: AnalyzedDataPoint.ID?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    private var baseline: Double {
        analyzedData.first?.baseline ?? 0
    }
    
    private var stdDev: Double {
        let values = analyzedData.map { $0.rawValue }
        return TrendAnalysisEngine.standardDeviation(values: values)
    }
    
    private var yDomain: ClosedRange<Double> {
        let values = analyzedData.map { $0.rawValue }
        guard let minVal = values.min(), let maxVal = values.max() else {
            return 0...100
        }
        let padding = (maxVal - minVal) * 0.15
        return (minVal - padding)...(maxVal + padding)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            chartView
            legendView
            if showEMA {
                Text("EMA responds faster than SMA to recent change")
                    .font(.caption2)
                    .foregroundStyle(RTColor.tertiaryText)
                    .accessibilityIdentifier(SurfaceID.metricChartEMA)
            }
            if showMA14 {
                Text("MA14 smooths longer trends than MA7")
                    .font(.caption2)
                    .foregroundStyle(RTColor.tertiaryText)
                    .accessibilityIdentifier(SurfaceID.metricChartMA14)
            }
            if showVolatility {
                volatilityStrip
            }
            if showMomentum {
                momentumStrip
            }
            if showRateOfChange {
                rateOfChangeStrip
            }
        }
        .background(AppBackground())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(SurfaceID.metricChartScrub)
    }
    
    // MARK: - Chart
    
    private var chartView: some View {
        Chart {
            if showBaselineBands {
                baselineBandMarks
            }
            if showMovingAverage {
                movingAverageMarks
            }
            if showMA14 {
                ma14Marks
            }
            if showEMA {
                emaMarks
            }
            mainDataMarks
            if showOutliers {
                outlierMarks
            }
            if showBaselineBands {
                baselineRule
            }
            if let selected = selectedPoint {
                selectionRule(for: selected)
            }
        }
        .frame(height: 240)
        .chartYScale(domain: yDomain)
        .chartXAxis {
            AxisMarks(values: .stride(by: analyzedData.count <= 14 ? .day : .weekOfYear)) { _ in
                AxisGridLine().foregroundStyle(RTColor.divider)
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    .foregroundStyle(RTColor.secondaryText)
            }
        }
        .chartYAxis {
            AxisMarks { _ in
                AxisGridLine().foregroundStyle(RTColor.divider)
                AxisValueLabel()
                    .foregroundStyle(RTColor.secondaryText)
            }
        }
        .chartBackground { proxy in
            annotationOverlay(proxy: proxy)
        }
        .chartOverlay { proxy in
            scrubOverlay(proxy: proxy)
        }
    }
    
    // MARK: - Chart Marks
    
    @ChartContentBuilder
    private var baselineBandMarks: some ChartContent {
        let cal = Calendar.current
        let low = baseline - 2 * stdDev
        let high = baseline + 2 * stdDev
        ForEach(analyzedData) { point in
            let endDate = cal.date(byAdding: .day, value: 1, to: point.date) ?? point.date
            let color = bandColor(zScore: point.zScore).opacity(0.08)
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
    private var movingAverageMarks: some ChartContent {
        ForEach(analyzedData) { point in
            if let ma = point.movingAverage7 {
                LineMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value("MA7", ma)
                )
                .foregroundStyle(metric.color.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                .interpolationMethod(.catmullRom)
            }
        }
    }

    /// Honest #244: elevates unused `AnalyzedDataPoint.movingAverage14` (SMA-14).
    @ChartContentBuilder
    private var ma14Marks: some ChartContent {
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

    /// Honest #242: elevates unused `AnalyzedDataPoint.ema7` (exponentialMovingAverage).
    @ChartContentBuilder
    private var emaMarks: some ChartContent {
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
    
    @ChartContentBuilder
    private var mainDataMarks: some ChartContent {
        let gradient = LinearGradient(
            colors: [metric.color.opacity(0.15), metric.color.opacity(0.0)],
            startPoint: .top,
            endPoint: .bottom
        )
        ForEach(analyzedData) { point in
            LineMark(
                x: .value("Date", point.date, unit: .day),
                y: .value("Value", point.rawValue)
            )
            .foregroundStyle(metric.color)
            .lineStyle(StrokeStyle(lineWidth: 2.5))
            .interpolationMethod(.catmullRom)
            
            AreaMark(
                x: .value("Date", point.date, unit: .day),
                y: .value("Value", point.rawValue)
            )
            .foregroundStyle(gradient)
            .interpolationMethod(.catmullRom)
            
            PointMark(
                x: .value("Date", point.date, unit: .day),
                y: .value("Value", point.rawValue)
            )
            .foregroundStyle(pointColor(point: point))
            .symbolSize(point.isOutlier ? 120 : (point.date.isToday ? 80 : 40))
        }
    }
    
    @ChartContentBuilder
    private var outlierMarks: some ChartContent {
        let outlierData = analyzedData.filter { $0.isOutlier }
        ForEach(outlierData) { point in
            PointMark(
                x: .value("Date", point.date, unit: .day),
                y: .value("Value", point.rawValue)
            )
            .foregroundStyle(.red.opacity(0.3))
            .symbolSize(200)
        }
    }
    
    @ChartContentBuilder
    private var baselineRule: some ChartContent {
        RuleMark(y: .value("Baseline", baseline))
            .foregroundStyle(RTColor.primaryText.opacity(0.2))
            .lineStyle(StrokeStyle(lineWidth: 1, dash: [6, 4]))
    }
    
    @ChartContentBuilder
    private func selectionRule(for selected: AnalyzedDataPoint) -> some ChartContent {
        RuleMark(x: .value("Selected", selected.date))
            .foregroundStyle(RTColor.primaryText.opacity(0.35))
            .lineStyle(StrokeStyle(lineWidth: 1))
        
        PointMark(
            x: .value("Selected", selected.date, unit: .day),
            y: .value("Value", selected.rawValue)
        )
        .foregroundStyle(metric.color)
        .symbolSize(120)
    }
    
    // MARK: - Overlays
    
    private func annotationOverlay(proxy: ChartProxy) -> some View {
        GeometryReader { geometry in
            if let selected = selectedPoint {
                let xPos = proxy.position(forX: selected.date) ?? 0
                let yPos = proxy.position(forY: selected.rawValue) ?? 0
                
                let deviation = selected.percentDeviation * 100
                let sign = deviation >= 0 ? "+" : ""
                let deviationStr = "\(sign)\(String(format: "%.1f", deviation))% vs baseline"
                let zSign = selected.zScore >= 0 ? "+" : ""
                let zScoreStr = "\(zSign)\(String(format: "%.1f", selected.zScore))σ"
                let dayDeltaStr: String? = {
                    guard let roc = selected.rateOfChange else { return nil }
                    let s = roc >= 0 ? "+" : ""
                    return "Day Δ \(s)\(String(format: "%.0f", roc * 100))%"
                }()
                
                ChartTooltip(
                    date: selected.date,
                    value: formattedValue(selected.rawValue),
                    unit: metric.unit,
                    deviation: deviationStr,
                    isOutlier: selected.isOutlier,
                    zScore: zScoreStr,
                    dayDelta: dayDeltaStr
                )
                .accessibilityIdentifier(SurfaceID.metricChartSelection)
                .accessibilityLabel(
                    ChartScrubSelection.enrichedCalloutText(
                        date: selected.date,
                        value: formattedValue(selected.rawValue),
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
    
    /// Drag scrub (Apple Health / WHOOP). iOS 16 deployment — DragGesture +
    /// ChartProxy instead of `chartXSelection` (iOS 17+).
    private func scrubOverlay(proxy: ChartProxy) -> some View {
        GeometryReader { geo in
            Rectangle()
                .fill(Color.clear)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            selectNearest(at: value.location, proxy: proxy, geo: geo)
                        }
                        .onEnded { _ in
                            selectedPoint = nil
                            lastHapticID = nil
                        }
                )
        }
    }
    
    private func selectNearest(at location: CGPoint, proxy: ChartProxy, geo: GeometryProxy) {
        let date: Date?
        if #available(iOS 17.0, *) {
            guard let plotFrame = proxy.plotFrame else { return }
            let x = location.x - geo[plotFrame].origin.x
            date = proxy.value(atX: x)
        } else {
            let width = geo.size.width
            guard width > 0,
                  let first = analyzedData.first?.date,
                  let last = analyzedData.last?.date else { return }
            date = ChartScrubSelection.date(
                atFraction: location.x / width,
                from: first,
                to: last
            )
        }
        guard let date,
              let idx = ChartScrubSelection.nearestIndex(
                in: analyzedData.map(\.date),
                to: date
              ) else { return }
        let point = analyzedData[idx]
        selectedPoint = point
        if point.id != lastHapticID {
            lastHapticID = point.id
            if !reduceMotion {
                Haptic.selectionChanged()
            }
        }
    }
    
    // MARK: - Legend
    
    private var legendView: some View {
        HStack(spacing: 16) {
            legendItem(color: metric.color, label: "Actual", dashed: false)
            if showMovingAverage {
                legendItem(color: metric.color.opacity(0.5), label: "7-day MA", dashed: true)
            }
            if showMA14 {
                legendItem(color: RTColor.recovery.opacity(0.9), label: "14-day MA", dashed: true)
            }
            if showEMA {
                legendItem(color: RTColor.hrv.opacity(0.85), label: "7-day EMA", dashed: true)
            }
            if showBaselineBands {
                legendItem(color: RTColor.tertiaryText, label: "Baseline", dashed: true)
            }
            if showOutliers {
                HStack(spacing: 4) {
                    Circle()
                        .fill(.red.opacity(0.3))
                        .frame(width: 8, height: 8)
                    Text("Outlier")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(RTColor.secondaryText)
                }
            }
            if showVolatility {
                legendItem(color: RTColor.caution, label: "Volatility", dashed: false)
            }
            if showMomentum {
                legendItem(color: RTColor.hrv, label: "Momentum", dashed: false)
            }
            if showRateOfChange {
                legendItem(color: RTColor.strain, label: "Day Δ", dashed: false)
            }
        }
        .padding(.top, 4)
    }
    
    private func legendItem(color: Color, label: String, dashed: Bool) -> some View {
        HStack(spacing: 6) {
            Rectangle()
                .fill(color)
                .frame(width: 16, height: dashed ? 2 : 3)
                .overlay(
                    Rectangle()
                        .stroke(color, style: dashed ? StrokeStyle(lineWidth: 2, dash: [4, 3]) : StrokeStyle())
                )
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(RTColor.secondaryText)
        }
    }
    
    // MARK: - Volatility Strip (Honest #240)

    /// Rolling 7-day coefficient of variation — elevated from unused
    /// `TrendAnalysisEngine.rollingVolatility` already stashed on AnalyzedDataPoint.
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
        // Soft glance bands on CV (std/mean).
        if cv >= 0.15 { return ("High", RTColor.warning) }
        if cv >= 0.08 { return ("Mild", RTColor.caution) }
        return ("Low", RTColor.optimal)
    }

    private var volatilityYDomain: ClosedRange<Double> {
        let vals = volatilityPoints.map(\.cv)
        let hi = max(vals.max() ?? 0.2, 0.2)
        return 0...(hi * 1.15)
    }

    private var volatilityStrip: some View {
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
                    // Soft band backgrounds (Low / Mild / High).
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
        .accessibilityIdentifier(SurfaceID.metricChartVolatility)
        .accessibilityLabel("Seven day rolling volatility")
    }

    // MARK: - Momentum Strip (Honest #241)

    /// 7-day windowed % change — elevates unused `TrendAnalysisEngine.momentum`.
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
        // Soft glance bands on fractional 7-day change.
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

    private var momentumStrip: some View {
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
        .accessibilityIdentifier(SurfaceID.metricChartMomentum)
        .accessibilityLabel("Seven day momentum")
    }

    // MARK: - Rate of Change Strip (Honest #243)

    /// Day-over-day fractional change — elevates unused `AnalyzedDataPoint.rateOfChange`
    /// from `TrendAnalysisEngine.rateOfChange` (distinct from 7-day momentum).
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
        // Tighter bands than momentum — daily noise is larger.
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

    private var rateOfChangeStrip: some View {
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
        .accessibilityIdentifier(SurfaceID.metricChartROC)
        .accessibilityLabel("Day over day rate of change")
    }

    // MARK: - Helpers
    
    private func pointColor(point: AnalyzedDataPoint) -> Color {
        if point.isOutlier { return .red }
        if point.date.isToday { return metric.color }
        return metric.color.opacity(0.6)
    }
    
    private func bandColor(zScore: Double) -> Color {
        let absZ = abs(zScore)
        if absZ > 2 { return .red }
        if absZ > 1 { return .orange }
        return .green
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
