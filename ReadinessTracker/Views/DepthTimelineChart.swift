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
    /// Honest #258: toggle ±2σ baseline bands (classic/Advanced parity). Default on.
    var showBaselineBands: Bool = true
    /// Honest #262: MA14 / EMA7 overlays (classic #247 parity). Default on.
    var showMA14: Bool = true
    var showEMA: Bool = true

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

    private var ma14: [Double] {
        TrendAnalysisEngine.movingAverage(values: values, window: 14)
    }

    private var ema7: [Double] {
        TrendAnalysisEngine.exponentialMovingAverage(values: values, window: 7)
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
                    .foregroundStyle(RTColor.primaryText)
                Spacer()
                if let i = selectedIndex, filteredPoints.indices.contains(i) {
                    Text("\(filteredPoints[i].date, format: .dateTime.month().day()): \(formatted(filteredPoints[i].value)) \(unit)")
                        .font(.caption)
                        .foregroundStyle(RTColor.secondaryText)
                }
            }

            if filteredPoints.count >= 2 {
                Chart {
                    // Honest #258: ±2σ z-score colored bands + baseline rule (classic/Advanced parity).
                    if showBaselineBands, stats.stdDev > 0 {
                        let cal = Calendar.current
                        let low = stats.baseline - 2 * stats.stdDev
                        let high = stats.baseline + 2 * stats.stdDev
                        ForEach(Array(filteredPoints.enumerated()), id: \.offset) { _, point in
                            let z = TrendAnalysisEngine.zScore(
                                value: point.value,
                                baseline: stats.baseline,
                                stdDev: stats.stdDev
                            )
                            let endDate = cal.date(byAdding: .day, value: 1, to: point.date) ?? point.date
                            RectangleMark(
                                xStart: .value("Date", point.date),
                                xEnd: .value("Date", endDate),
                                yStart: .value("Low", low),
                                yEnd: .value("High", high)
                            )
                            .foregroundStyle(bandColor(zScore: z).opacity(0.08))
                        }

                        RuleMark(y: .value("Baseline", stats.baseline))
                            .foregroundStyle(RTColor.primaryText.opacity(0.25))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    }

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
                            .foregroundStyle(RTColor.primaryText.opacity(0.7))
                            .symbol(.circle)
                            .symbolSize(12)
                        }
                    }

                    // Honest #262: MA14 LineMark (classic #247 / Advanced #244 parity).
                    if showMA14 {
                        ForEach(Array(filteredPoints.enumerated()), id: \.offset) { i, point in
                            if i - 13 >= 0 && i - 13 < ma14.count {
                                LineMark(
                                    x: .value("Date", point.date, unit: .day),
                                    y: .value("MA14", ma14[i - 13])
                                )
                                .foregroundStyle(RTColor.recovery.opacity(0.9))
                                .lineStyle(StrokeStyle(lineWidth: 1.75, dash: [8, 4]))
                                .interpolationMethod(.catmullRom)
                            }
                        }
                    }

                    // Honest #262: EMA7 LineMark (classic #247 / Advanced #242 parity).
                    if showEMA {
                        ForEach(Array(filteredPoints.enumerated()), id: \.offset) { i, point in
                            if i < ema7.count {
                                LineMark(
                                    x: .value("Date", point.date, unit: .day),
                                    y: .value("EMA7", ema7[i])
                                )
                                .foregroundStyle(RTColor.hrv.opacity(0.85))
                                .lineStyle(StrokeStyle(lineWidth: 2, dash: [6, 3]))
                                .interpolationMethod(.catmullRom)
                            }
                        }
                    }
                }
                .chartYScale(domain: domain)
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisGridLine().foregroundStyle(RTColor.divider)
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
                                            // date range via ChartScrubSelection.
                                            let width = geo.size.width
                                            guard width > 0,
                                                  let first = filteredPoints.first?.date,
                                                  let last = filteredPoints.last?.date else { return }
                                            date = ChartScrubSelection.date(
                                                atFraction: value.location.x / width,
                                                from: first,
                                                to: last
                                            )
                                        }
                                        guard let date else { return }
                                        selectedIndex = ChartScrubSelection.nearestIndex(
                                            in: filteredPoints.map(\.date),
                                            to: date
                                        )
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

    /// Classic/Advanced parity: green <|z|<1, orange <|z|<2, red |z|>2.
    private func bandColor(zScore: Double) -> Color {
        let absZ = abs(zScore)
        if absZ > 2 { return .red }
        if absZ > 1 { return .orange }
        return .green
    }

    private func formatted(_ value: Double) -> String {
        value == floor(value) ? "\(Int(value))" : String(format: "%.1f", value)
    }
}
