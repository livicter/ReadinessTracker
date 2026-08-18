import SwiftUI
import Charts

/// Reusable interactive depth timeline: line with point markers, ±2σ baseline
/// band, 7-day moving average, outlier highlighting, tap tooltip.
struct DepthTimelineChart: View {
    let title: String
    let unit: String
    let color: Color
    let points: [(date: Date, value: Double)]
    var period: TrendPeriod = .week

    @State private var selectedIndex: Int?

    /// Points within the selected `period` window, anchored at the latest date.
    private var filteredPoints: [(date: Date, value: Double)] {
        guard let latest = points.map(\.date).max() else { return points }
        guard let cutoff = Calendar.current.date(byAdding: .day, value: -period.rawValue, to: latest) else { return points }
        return points.filter { $0.date >= cutoff }
    }

    private var values: [Double] { filteredPoints.map { $0.value } }

    /// Baseline + σ computed once per render; pass to `isOutlier` instead of
    /// recomputing per point.
    private var stats: (baseline: Double, stdDev: Double) {
        (TrendAnalysisEngine.mean(values: values), TrendAnalysisEngine.standardDeviation(values: values))
    }

    private var ma7: [Double] {
        TrendAnalysisEngine.movingAverage(values: values, window: 7)
    }

    private func isOutlier(_ value: Double, baseline: Double, stdDev: Double) -> Bool {
        abs(TrendAnalysisEngine.zScore(value: value, baseline: baseline, stdDev: stdDev)) > 2
    }

    private var domain: ClosedRange<Double> {
        let (baseline, stdDev) = stats
        guard let lo = values.min(), let hi = values.max() else { return 0...100 }
        let pad = max((hi - lo) * 0.15, stdDev * 0.5, 0.001)
        return min(lo - pad, baseline - 2 * stdDev)...max(hi + pad, baseline + 2 * stdDev)
    }

    var body: some View {
        let stats = self.stats
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                Spacer()
                if let i = selectedIndex, filteredPoints.indices.contains(i) {
                    Text("\(filteredPoints[i].date, format: .dateTime.month().day()): \(formatted(filteredPoints[i].value)) \(unit)")
                        .font(.caption)
                        .foregroundStyle(RTColor.secondaryText)
                }
            }

            if filteredPoints.count >= 2 {
                Chart {
                    // ±2σ baseline band
                    if stats.stdDev > 0 {
                        RectangleMark(
                            xStart: .value("s", filteredPoints.first!.date),
                            xEnd: .value("e", filteredPoints.last!.date),
                            yStart: .value("lo", stats.baseline - 2 * stats.stdDev),
                            yEnd: .value("hi", stats.baseline + 2 * stats.stdDev)
                        )
                        .foregroundStyle(color.opacity(0.08))
                    }

                    RuleMark(y: .value("Baseline", stats.baseline))
                        .foregroundStyle(.white.opacity(0.25))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))

                    ForEach(Array(filteredPoints.enumerated()), id: \.offset) { i, point in
                        LineMark(
                            x: .value("Date", point.date, unit: .day),
                            y: .value("Value", point.value)
                        )
                        .foregroundStyle(color)
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 2.5))

                        if isOutlier(point.value, baseline: stats.baseline, stdDev: stats.stdDev) {
                            PointMark(
                                x: .value("Date", point.date, unit: .day),
                                y: .value("Value", point.value)
                            )
                            .foregroundStyle(RTColor.warning)
                            .symbolSize(90)
                        } else {
                            PointMark(
                                x: .value("Date", point.date, unit: .day),
                                y: .value("Value", point.value)
                            )
                            .foregroundStyle(color.opacity(0.6))
                            .symbolSize(30)
                        }

                        // MA7 overlay (aligned: ma7[j] corresponds to points[j + 6])
                        if i - 6 >= 0 && i - 6 < ma7.count {
                            PointMark(
                                x: .value("Date", point.date, unit: .day),
                                y: .value("MA7", ma7[i - 6])
                            )
                            .foregroundStyle(.white.opacity(0.7))
                            .symbol(.circle)
                            .symbolSize(12)
                        }
                    }
                }
                .chartYScale(domain: domain)
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisGridLine().foregroundStyle(.white.opacity(0.05))
                        AxisValueLabel().foregroundStyle(RTColor.secondaryText)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                            .foregroundStyle(RTColor.secondaryText)
                    }
                }
                .frame(height: 200)
                .chartOverlay { proxy in
                    GeometryReader { geo in
                        Rectangle()
                            .fill(.clear)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        let date: Date?
                                        if #available(iOS 17.0, *) {
                                            guard let plotFrame = proxy.plotFrame else { return }
                                            let x = value.location.x - geo[plotFrame].origin.x
                                            date = proxy.value(atX: x)
                                        } else {
                                            // iOS 16: no plotFrame — map the touch onto the
                                            // date range manually across the plot width.
                                            let width = geo.size.width
                                            guard width > 0,
                                                  let first = filteredPoints.first?.date,
                                                  let last = filteredPoints.last?.date else { return }
                                            let fraction = min(max(value.location.x / width, 0), 1)
                                            date = first.addingTimeInterval(fraction * last.timeIntervalSince(first))
                                        }
                                        guard let date else { return }
                                        selectedIndex = filteredPoints.indices.min(by: {
                                            abs(filteredPoints[$0].date.timeIntervalSince(date)) <
                                            abs(filteredPoints[$1].date.timeIntervalSince(date))
                                        })
                                    }
                                    .onEnded { _ in selectedIndex = nil }
                            )
                    }
                }
            } else {
                Text("Need more data")
                    .font(.caption)
                    .foregroundStyle(RTColor.secondaryText)
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func formatted(_ value: Double) -> String {
        value == floor(value) ? "\(Int(value))" : String(format: "%.1f", value)
    }
}
