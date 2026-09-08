import SwiftUI
import Charts

/// WHOOP-style 7-day sleep quality: clearer average score ring, compact sparkline,
/// score bars with zone bands, and daily mini rings.
struct SleepQualityTrend: View {
    let history: [(date: Date, sleepScore: Int, sleepHours: Double, efficiency: Double)]

    private var averageScore: Double {
        guard !history.isEmpty else { return 0 }
        return Double(history.map { $0.sleepScore }.reduce(0, +)) / Double(history.count)
    }

    private var trendDirection: TrendDirection {
        guard history.count >= 3 else { return .flat }
        let recent = Array(history.suffix(3)).map { $0.sleepScore }.reduce(0, +) / 3
        let older = Array(history.prefix(3)).map { $0.sleepScore }.reduce(0, +) / 3
        let diff = Double(recent - older)
        if abs(diff) < 5 { return .flat }
        return diff > 0 ? .up : .down
    }

    private var scoreColor: Color {
        switch averageScore {
        case 80...100: return RTColor.optimal
        case 60..<80: return RTColor.good
        case 40..<60: return RTColor.caution
        default: return RTColor.warning
        }
    }

    private var scoreLabel: String {
        switch averageScore {
        case 80...100: return "Excellent"
        case 60..<80: return "Good"
        case 40..<60: return "Fair"
        default: return "Poor"
        }
    }

    /// Last 7 nights oldest → newest for spark.
    private var sparklineValues: [Double] {
        let sorted = history.sorted { $0.date < $1.date }
        return Array(sorted.suffix(7).map { Double($0.sleepScore) })
    }

    private var last7: [(date: Date, sleepScore: Int, sleepHours: Double, efficiency: Double)] {
        Array(history.sorted { $0.date < $1.date }.suffix(7))
    }

    var body: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 14) {
                // Header + clearer average score ring
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sleep Quality Trend")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(RTColor.primaryText)

                        HStack(spacing: 6) {
                            Text("Avg \(Int(averageScore.rounded())) · \(scoreLabel)")
                                .font(.subheadline)
                                .foregroundStyle(scoreColor)

                            CompactTrendIndicator(direction: trendDirection, percentChange: nil)
                        }
                    }

                    Spacer()

                    ZStack {
                        Circle()
                            .stroke(RTColor.surfaceHighlight, lineWidth: 6)

                        Circle()
                            .trim(from: 0, to: averageScore / 100)
                            .stroke(scoreColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                            .rotationEffect(.degrees(-90))

                        Text("\(Int(averageScore.rounded()))")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(RTColor.primaryText)
                            .monospacedDigit()
                    }
                    .frame(width: 56, height: 56)
                    .accessibilityIdentifier(SurfaceID.sleepQualityScore)
                    .accessibilityLabel("Average sleep quality \(Int(averageScore.rounded()))")
                }

                // Compact 7-day sparkline
                if sparklineValues.count >= 2 {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("7-Day Quality")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(RTColor.secondaryText)
                            Spacer()
                            Text("7D")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(RTColor.secondaryText)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(RTColor.divider.opacity(0.4))
                                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                        }
                        AnimatedSparkline(data: sparklineValues, color: RTColor.sleep)
                            .frame(height: 28)
                            .accessibilityIdentifier(SurfaceID.sleepQualitySpark)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Score chart
                if history.count >= 2 {
                    Chart(history, id: \.date) { point in
                        RectangleMark(
                            xStart: .value("Date", point.date),
                            xEnd: .value("Date", Calendar.current.date(byAdding: .day, value: 1, to: point.date) ?? point.date),
                            yStart: .value("Score", 80),
                            yEnd: .value("Score", 100)
                        )
                        .foregroundStyle(RTColor.optimal.opacity(0.05))

                        RectangleMark(
                            xStart: .value("Date", point.date),
                            xEnd: .value("Date", Calendar.current.date(byAdding: .day, value: 1, to: point.date) ?? point.date),
                            yStart: .value("Score", 60),
                            yEnd: .value("Score", 80)
                        )
                        .foregroundStyle(RTColor.caution.opacity(0.05))

                        BarMark(
                            x: .value("Date", point.date, unit: .day),
                            y: .value("Score", point.sleepScore)
                        )
                        .foregroundStyle(barColor(point.sleepScore))
                        .cornerRadius(4, style: .continuous)

                        RuleMark(y: .value("Average", averageScore))
                            .foregroundStyle(RTColor.primaryText.opacity(0.3))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    }
                    .frame(height: 140)
                    .chartYScale(domain: 0...100)
                    .chartYAxis {
                        AxisMarks { _ in
                            AxisGridLine().foregroundStyle(RTColor.divider)
                            AxisValueLabel {
                                Text("pts")
                                    .font(.system(size: 9))
                                    .foregroundStyle(RTColor.secondaryText)
                            }
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day)) { _ in
                            AxisGridLine().foregroundStyle(RTColor.divider)
                            AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                                .foregroundStyle(RTColor.secondaryText)
                        }
                    }
                }

                // Daily breakdown rings
                if last7.count >= 2 {
                    HStack(spacing: 8) {
                        ForEach(last7, id: \.date) { day in
                            VStack(spacing: 4) {
                                let dayLabel = Calendar.current.shortWeekdaySymbols[Calendar.current.component(.weekday, from: day.date) - 1]
                                Text(String(dayLabel.prefix(1)))
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(RTColor.secondaryText)

                                ZStack {
                                    Circle()
                                        .stroke(barColor(day.sleepScore).opacity(0.3), lineWidth: 3)
                                        .frame(width: 28, height: 28)

                                    Circle()
                                        .trim(from: 0, to: Double(day.sleepScore) / 100)
                                        .stroke(barColor(day.sleepScore), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                                        .rotationEffect(.degrees(-90))
                                        .frame(width: 28, height: 28)

                                    Text("\(day.sleepScore)")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundStyle(RTColor.primaryText)
                                }

                                Text("\(String(format: "%.1f", day.sleepHours))h")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundStyle(RTColor.secondaryText)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(SurfaceID.sleepQualityTrend)
        .accessibilityLabel("Sleep Quality Trend")
    }

    private func barColor(_ score: Int) -> Color {
        switch score {
        case 80...100: return RTColor.optimal
        case 60..<80: return RTColor.good
        case 40..<60: return RTColor.caution
        default: return RTColor.warning
        }
    }
}
