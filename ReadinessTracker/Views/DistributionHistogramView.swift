import SwiftUI
import Charts

/// Distribution histogram showing how often values fall into each zone.
/// Helps users understand their typical ranges vs outliers.
struct DistributionHistogramView: View {
    let history: [(date: Date, value: Double)]
    let metric: MetricType
    
    private var buckets: [HistogramBucket] {
        let values = history.map { $0.value }
        guard let minVal = values.min(), let maxVal = values.max(), minVal < maxVal else { return [] }
        
        let bucketCount = min(8, max(4, values.count / 3))
        let range = maxVal - minVal
        let bucketWidth = range / Double(bucketCount)
        
        var buckets: [HistogramBucket] = []
        for i in 0..<bucketCount {
            let lower = minVal + Double(i) * bucketWidth
            let upper = lower + bucketWidth
            let count = values.filter { $0 >= lower && $0 < upper }.count
            let isCurrent = history.last.map { $0.value >= lower && $0.value < upper } ?? false
            buckets.append(HistogramBucket(
                range: lower...upper,
                count: count,
                percentage: Double(count) / Double(values.count),
                isCurrent: isCurrent
            ))
        }
        
        // Handle max value edge case
        if let last = buckets.last {
            buckets[buckets.count - 1] = HistogramBucket(
                range: last.range.lowerBound...maxVal,
                count: last.count,
                percentage: last.percentage,
                isCurrent: last.isCurrent
            )
        }
        
        return buckets
    }
    
    var body: some View {
        NativeCard {
        VStack(alignment: .leading, spacing: 12) {
            NativeSectionHeader(title: "Distribution", action: nil)
                .padding(.horizontal, 4)
            
            if buckets.isEmpty {
                Text("Not enough data")
                    .font(.subheadline)
                    .foregroundStyle(RTColor.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            } else {
                Chart(buckets) { bucket in
                    BarMark(
                        x: .value("Range", bucket.label(for: metric)),
                        y: .value("Count", bucket.count)
                    )
                    .foregroundStyle(bucket.isCurrent ? metric.color : metric.color.opacity(0.5))
                    .cornerRadius(4, style: .continuous)
                }
                .frame(height: 160)
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisGridLine().foregroundStyle(.white.opacity(0.05))
                        AxisValueLabel()
                            .foregroundStyle(RTColor.secondaryText)
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisGridLine().foregroundStyle(.white.opacity(0.05))
                        AxisValueLabel {
                            if let text = value.as(String.self) {
                                Text(text)
                                    .font(.system(size: 9))
                                    .foregroundStyle(RTColor.secondaryText)
                                    .rotationEffect(.degrees(-45))
                            }
                        }
                    }
                }
                
                // Distribution stats
                HStack(spacing: 16) {
                    let values = history.map { $0.value }
                    StatMini(label: "Range", value: "\(formattedValue(values.min() ?? 0))–\(formattedValue(values.max() ?? 0))")
                    StatMini(label: "Median", value: formattedValue(median(values)))
                    StatMini(label: "Mode", value: formattedValue(mode(values)))
                }
            }
        }
        }
        .background(AppBackground())
    }

    private func formattedValue(_ value: Double) -> String {
        switch metric {
        case .sleep: return String(format: "%.1f", value)
        case .hrv, .restingHR, .activeCalories, .bloodOxygen: return "\(Int(value))"
        }
    }
    
    private func median(_ values: [Double]) -> Double {
        let sorted = values.sorted()
        let count = sorted.count
        guard count > 0 else { return 0 }
        if count % 2 == 0 {
            return (sorted[count / 2 - 1] + sorted[count / 2]) / 2
        } else {
            return sorted[count / 2]
        }
    }
    
    private func mode(_ values: [Double]) -> Double {
        // Simple: return the most common bucket's midpoint
        let buckets = self.buckets
        guard let maxBucket = buckets.max(by: { $0.count < $1.count }) else { return values.first ?? 0 }
        return (maxBucket.range.lowerBound + maxBucket.range.upperBound) / 2
    }
}

struct HistogramBucket: Identifiable {
    let id = UUID()
    let range: ClosedRange<Double>
    let count: Int
    let percentage: Double
    let isCurrent: Bool
    
    func label(for metric: MetricType) -> String {
        switch metric {
        case .sleep:
            return "\(Int(range.lowerBound))-\(Int(range.upperBound))h"
        case .hrv, .restingHR, .activeCalories, .bloodOxygen:
            return "\(Int(range.lowerBound))-\(Int(range.upperBound))"
        }
    }
}

struct StatMini: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(RTColor.secondaryText)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
    }
}
