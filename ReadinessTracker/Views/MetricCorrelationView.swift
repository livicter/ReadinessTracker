import SwiftUI
import Charts

/// Scatter plot showing correlation between two metrics with real Pearson correlation.
/// Apple-native styling with clean annotation.
struct MetricCorrelationView: View {
    let history: [DailyHealthData]
    let xMetric: MetricType
    let yMetric: MetricType
    
    private var correlationData: [(x: Double, y: Double, date: Date)] {
        history.compactMap { data in
            guard let x = metricValue(data, for: xMetric),
                  let y = metricValue(data, for: yMetric) else { return nil }
            return (x, y, data.date)
        }
    }
    
    private var correlation: Double {
        let xVals = correlationData.map { $0.x }
        let yVals = correlationData.map { $0.y }
        return TrendAnalysisEngine.pearsonCorrelation(x: xVals, y: yVals)
    }
    
    private var insight: String {
        let r = abs(correlation)
        let direction = correlation > 0 ? "positive" : "negative"
        
        if r < 0.2 {
            return "No meaningful correlation between \(xMetric.title) and \(yMetric.title)."
        } else if r < 0.5 {
            return "Weak \(direction) correlation. These metrics move together somewhat, but other factors have more influence."
        } else if r < 0.7 {
            return "Moderate \(direction) correlation. When \(xMetric.title) changes, \(yMetric.title) tends to follow."
        } else {
            return "Strong \(direction) correlation. These metrics are closely linked."
        }
    }
    
    var body: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(xMetric.title) vs \(yMetric.title)")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(RTColor.primaryText)
                        
                        HStack(spacing: 4) {
                            Text("r = \(String(format: "%.2f", correlation))")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(correlationColor)
                            
                            Text(correlationLabel)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(RTColor.secondaryText)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(correlationColor.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }
                    
                    Spacer()
                }
                
                // Scatter chart
                if correlationData.count >= 3 {
                    Chart {
                        ForEach(correlationData, id: \.date) { point in
                            PointMark(
                                x: .value(xMetric.title, point.x),
                                y: .value(yMetric.title, point.y)
                            )
                            .foregroundStyle(xMetric.color.opacity(0.7))
                            .symbolSize(60)
                        }

                        // Trend line
                        if let trendLine = calculateTrendLine() {
                            let trendData = [TrendLinePoint(x: trendLine[0].x, y: trendLine[0].y),
                                             TrendLinePoint(x: trendLine[1].x, y: trendLine[1].y)]
                            ForEach(trendData) { pt in
                                LineMark(
                                    x: .value(xMetric.title, pt.x),
                                    y: .value(yMetric.title, pt.y)
                                )
                                .foregroundStyle(correlationColor.opacity(0.4))
                                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 3]))
                            }
                        }
                    }
                    .frame(height: 180)
                    .chartXAxis {
                        AxisMarks { _ in
                            AxisGridLine().foregroundStyle(.white.opacity(0.05))
                            AxisValueLabel()
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
                } else {
                    Text("Not enough data for correlation analysis")
                        .font(.subheadline)
                        .foregroundStyle(RTColor.secondaryText)
                        .frame(height: 180)
                        .frame(maxWidth: .infinity)
                }
                
                // Insight text
                Text(insight)
                    .font(.subheadline)
                    .foregroundStyle(RTColor.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .background(AppBackground())
    }
    
    private var correlationColor: Color {
        let r = abs(correlation)
        if r < 0.3 { return RTColor.secondaryText }
        if r < 0.5 { return RTColor.caution }
        if r < 0.7 { return RTColor.good }
        return RTColor.optimal
    }
    
    private var correlationLabel: String {
        let r = abs(correlation)
        if r < 0.2 { return "None" }
        if r < 0.4 { return "Weak" }
        if r < 0.6 { return "Moderate" }
        if r < 0.8 { return "Strong" }
        return "Very Strong"
    }
    
    private func calculateTrendLine() -> [(x: Double, y: Double)]? {
        guard correlationData.count >= 3 else { return nil }
        let xVals = correlationData.map { $0.x }
        let yVals = correlationData.map { $0.y }

        // Least-squares regression of y against the actual x values
        let n = Double(xVals.count)
        let sumX = xVals.reduce(0, +)
        let sumY = yVals.reduce(0, +)
        let sumXY = zip(xVals, yVals).map(*).reduce(0, +)
        let sumX2 = xVals.map { $0 * $0 }.reduce(0, +)

        let denominator = n * sumX2 - sumX * sumX
        guard denominator != 0 else { return nil }

        let slope = (n * sumXY - sumX * sumY) / denominator
        let intercept = (sumY - slope * sumX) / n
        guard slope != 0 else { return nil }

        let minX = xVals.min() ?? 0
        let maxX = xVals.max() ?? 0

        return [
            (minX, intercept + slope * minX),
            (maxX, intercept + slope * maxX)
        ]
    }

    private func metricValue(_ data: DailyHealthData, for metric: MetricType) -> Double? {
        switch metric {
        case .sleep: return data.sleepHours
        case .hrv: return data.hrv
        case .restingHR: return data.restingHeartRate
        case .activeCalories: return data.activeCalories
        case .bloodOxygen: return data.bloodOxygen
        }
    }
}

struct TrendLinePoint: Identifiable {
    let id = UUID()
    let x: Double
    let y: Double
}
