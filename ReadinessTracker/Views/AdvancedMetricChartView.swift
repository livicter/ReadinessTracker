import SwiftUI
import Charts

/// Advanced chart view showing real data science analysis on user's actual health data.
/// Apple-native styling with a solid-surface tooltip and clean annotations.
struct AdvancedMetricChartView: View {
    let metric: MetricType
    let analyzedData: [AnalyzedDataPoint]
    let showBaselineBands: Bool
    let showMovingAverage: Bool
    let showOutliers: Bool
    
    @State private var selectedPoint: AnalyzedDataPoint?
    
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
        }
        .background(AppBackground())
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
                AxisGridLine().foregroundStyle(.white.opacity(0.05))
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    .foregroundStyle(RTColor.secondaryText)
            }
        }
        .chartYAxis {
            AxisMarks { _ in
                AxisGridLine().foregroundStyle(.white.opacity(0.05))
                AxisValueLabel()
                    .foregroundStyle(RTColor.secondaryText)
            }
        }
        .chartBackground { proxy in
            annotationOverlay(proxy: proxy)
        }
        .chartBackground { proxy in
            tapOverlay(proxy: proxy)
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
            .foregroundStyle(.white.opacity(0.2))
            .lineStyle(StrokeStyle(lineWidth: 1, dash: [6, 4]))
    }
    
    @ChartContentBuilder
    private func selectionRule(for selected: AnalyzedDataPoint) -> some ChartContent {
        RuleMark(x: .value("Selected", selected.date))
            .foregroundStyle(.white.opacity(0.3))
            .lineStyle(StrokeStyle(lineWidth: 1))
    }
    
    // MARK: - Overlays
    
    private func annotationOverlay(proxy: ChartProxy) -> some View {
        GeometryReader { geometry in
            if let selected = selectedPoint {
                let xPos = proxy.position(forX: selected.date) ?? 0
                let yPos = proxy.position(forY: selected.rawValue) ?? 0
                
                let deviation = selected.percentDeviation * 100
                let sign = deviation >= 0 ? "+" : ""
                let deviationStr = "\(sign)\(String(format: "%.1f", deviation))%"
                
                ChartTooltip(
                    date: selected.date,
                    value: formattedValue(selected.rawValue),
                    unit: metric.unit,
                    deviation: deviationStr,
                    isOutlier: selected.isOutlier
                )
                .position(
                    x: min(max(xPos, 80), geometry.size.width - 80),
                    y: max(yPos - 70, 50)
                )
            }
        }
    }
    
    private func tapOverlay(proxy: ChartProxy) -> some View {
        GeometryReader { _ in
            Rectangle()
                .fill(Color.clear)
                .contentShape(Rectangle())
                .onTapGesture { location in
                    if let date = proxy.value(atX: location.x, as: Date.self) {
                        selectedPoint = analyzedData.min(by: {
                            abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
                        })
                    }
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
            if showBaselineBands {
                legendItem(color: .white.opacity(0.3), label: "Baseline", dashed: true)
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
