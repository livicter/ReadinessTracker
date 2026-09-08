import SwiftUI
import Charts

/// WHOOP-style sleep consistency: overall score ring, Bedtime | Wake dual metrics,
/// 7-night bedtime deviation dots/bars, and a compact consistency sparkline.
struct SleepConsistencyTracker: View {
    let history: [(date: Date, sleepStart: Date?, sleepEnd: Date?, sleepHours: Double)]

    private var bedtimeConsistency: Double {
        guard history.count >= 3 else { return 0 }
        let bedtimes = history.compactMap { $0.sleepStart }
        guard bedtimes.count >= 3 else { return 0 }
        return consistencyScore(for: bedtimes)
    }

    private var wakeTimeConsistency: Double {
        guard history.count >= 3 else { return 0 }
        let wakeTimes = history.compactMap { $0.sleepEnd }
        guard wakeTimes.count >= 3 else { return 0 }
        return consistencyScore(for: wakeTimes)
    }

    private var overallScore: Double {
        (bedtimeConsistency + wakeTimeConsistency) / 2
    }

    private var scoreColor: Color {
        switch overallScore {
        case 80...100: return RTColor.optimal
        case 60..<80: return RTColor.good
        case 40..<60: return RTColor.caution
        default: return RTColor.warning
        }
    }

    private var scoreLabel: String {
        switch overallScore {
        case 80...100: return "Excellent"
        case 60..<80: return "Good"
        case 40..<60: return "Fair"
        default: return "Poor"
        }
    }

    /// Std-dev-based consistency score that handles midnight wrap-around:
    /// minutes-from-midnight are normalized into a circular range around an
    /// anchor, so 23:30 and 00:30 are treated as 60 minutes apart, not 1380.
    private func consistencyScore(for times: [Date]) -> Double {
        let minutes = times.map { Calendar.current.component(.hour, from: $0) * 60 + Calendar.current.component(.minute, from: $0) }

        // Wrap each sample into [anchor - 720, anchor + 720) so times near midnight stay close
        let anchor = minutes[0]
        let wrapped = minutes.map { anchor + (($0 - anchor + 2160) % 1440) - 720 }

        let mean = Double(wrapped.reduce(0, +)) / Double(wrapped.count)
        let variance = wrapped.map { pow(Double($0) - mean, 2) }.reduce(0, +) / Double(wrapped.count)
        let stdDev = sqrt(variance)

        // Lower std dev = higher consistency (max 120 min std dev = 0%, 0 min = 100%)
        return max(0, min(100, 100 - (stdDev / 120) * 100))
    }

    /// Last 7 nights with bedtime (oldest → newest) for dots/bars + spark.
    private var last7Bedtimes: [(date: Date, minutes: Double)] {
        let points = history.compactMap { item -> (date: Date, minutes: Double)? in
            guard let start = item.sleepStart else { return nil }
            let mins = Double(
                Calendar.current.component(.hour, from: start) * 60 +
                Calendar.current.component(.minute, from: start)
            )
            return (item.date, mins)
        }
        .sorted { $0.date < $1.date }
        return Array(points.suffix(7))
    }

    /// Circular-mean bedtime (minutes) for the last-7 window.
    private var bedtimeMeanMinutes: Double {
        let vals = last7Bedtimes.map(\.minutes)
        guard !vals.isEmpty else { return 0 }
        let anchor = vals[0]
        let wrapped = vals.map { anchor + (($0 - anchor + 2160).truncatingRemainder(dividingBy: 1440)) - 720 }
        return wrapped.reduce(0, +) / Double(wrapped.count)
    }

    /// Per-night deviation from mean bedtime (minutes); positive = later.
    private var bedtimeDeviations: [Double] {
        let mean = bedtimeMeanMinutes
        return last7Bedtimes.map { point in
            let anchor = mean
            let wrapped = anchor + ((point.minutes - anchor + 2160).truncatingRemainder(dividingBy: 1440)) - 720
            return wrapped - mean
        }
    }

    /// Rolling consistency proxy for spark (higher = more regular bedtimes).
    private var sparklineValues: [Double] {
        let points = history.compactMap { $0.sleepStart }.sorted()
        guard points.count >= 3 else { return [] }
        var scores: [Double] = []
        for i in 2..<points.count {
            let window = Array(points[(i - 2)...i])
            scores.append(consistencyScore(for: window))
        }
        return Array(scores.suffix(7))
    }

    var body: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 14) {
                // Header + clearer score ring
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sleep Consistency")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(RTColor.primaryText)

                        Text("\(Int(overallScore.rounded()))% · \(scoreLabel)")
                            .font(.subheadline)
                            .foregroundStyle(scoreColor)
                    }

                    Spacer()

                    ZStack {
                        Circle()
                            .stroke(RTColor.surfaceHighlight, lineWidth: 6)

                        Circle()
                            .trim(from: 0, to: overallScore / 100)
                            .stroke(scoreColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                            .rotationEffect(.degrees(-90))

                        Text("\(Int(overallScore.rounded()))")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(RTColor.primaryText)
                            .monospacedDigit()
                    }
                    .frame(width: 56, height: 56)
                    .accessibilityIdentifier(SurfaceID.sleepConsistencyScore)
                    .accessibilityLabel("Sleep consistency \(Int(overallScore.rounded())) percent")
                }

                // Bedtime | Wake dual metric
                HStack(spacing: 12) {
                    dualColumn(
                        label: "Bedtime",
                        score: bedtimeConsistency,
                        icon: "moon.fill",
                        color: RTColor.sleep
                    )

                    Rectangle()
                        .fill(RTColor.divider)
                        .frame(width: 1)
                        .padding(.vertical, 4)

                    dualColumn(
                        label: "Wake Time",
                        score: wakeTimeConsistency,
                        icon: "sun.max.fill",
                        color: RTColor.caution
                    )
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier(SurfaceID.sleepConsistencyDual)

                // 7-night bedtime deviation dots / bars
                if last7Bedtimes.count >= 2 {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Bedtime vs Average")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(RTColor.secondaryText)
                            Spacer()
                            Text(meanBedtimeCaption)
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(RTColor.tertiaryText)
                                .monospacedDigit()
                        }

                        bedtimeDotsBars
                            .frame(height: 56)
                            .accessibilityIdentifier(SurfaceID.sleepConsistencyBedtime)
                            .accessibilityLabel("Bedtime consistency last seven nights")
                    }
                }

                // Compact consistency sparkline
                if sparklineValues.count >= 2 {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("7-Night Consistency")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(RTColor.secondaryText)
                            Spacer()
                            Text("\(Int(overallScore.rounded()))%")
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(scoreColor)
                                .monospacedDigit()
                        }
                        AnimatedSparkline(data: sparklineValues, color: RTColor.consistency)
                            .frame(height: 28)
                            .accessibilityIdentifier(SurfaceID.sleepConsistencySpark)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Bedtime trend chart (kept for scrub-friendly detail)
                if history.compactMap({ $0.sleepStart }).count >= 2 {
                    Text("Bedtime Trend")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RTColor.secondaryText)
                        .textCase(.uppercase)

                    bedtimeChart
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(SurfaceID.sleepConsistency)
        .accessibilityLabel("Sleep Consistency")
    }

    private var meanBedtimeCaption: String {
        let mins = Int(bedtimeMeanMinutes.rounded())
        let wrapped = ((mins % 1440) + 1440) % 1440
        let h = wrapped / 60
        let m = wrapped % 60
        return String(format: "avg %02d:%02d", h, m)
    }

    private var bedtimeDotsBars: some View {
        let deviations = bedtimeDeviations
        let maxAbs = max(15, deviations.map { abs($0) }.max() ?? 15)

        return GeometryReader { geo in
            let count = max(1, last7Bedtimes.count)
            let slot = geo.size.width / CGFloat(count)
            let midY = geo.size.height / 2

            ZStack(alignment: .topLeading) {
                // Average baseline
                Path { path in
                    path.move(to: CGPoint(x: 0, y: midY))
                    path.addLine(to: CGPoint(x: geo.size.width, y: midY))
                }
                .stroke(RTColor.primaryText.opacity(0.22), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))

                ForEach(Array(last7Bedtimes.enumerated()), id: \.offset) { index, point in
                    let deviation = deviations[index]
                    let barH = CGFloat(abs(deviation) / maxAbs) * (geo.size.height * 0.42)
                    let x = slot * CGFloat(index) + slot / 2
                    let isLate = deviation >= 0
                    let barColor = abs(deviation) < 15
                        ? RTColor.optimal
                        : (abs(deviation) < 45 ? RTColor.caution : RTColor.warning)

                    // Vertical bar from mean toward bedtime
                    Capsule()
                        .fill(barColor.opacity(0.55))
                        .frame(width: 5, height: max(4, barH))
                        .position(
                            x: x,
                            y: isLate ? midY + max(2, barH) / 2 : midY - max(2, barH) / 2
                        )

                    // Dot at bedtime
                    Circle()
                        .fill(barColor)
                        .frame(width: 8, height: 8)
                        .position(
                            x: x,
                            y: isLate ? midY + max(2, barH) : midY - max(2, barH)
                        )

                    // Weekday label
                    let dayLabel = Calendar.current.shortWeekdaySymbols[
                        Calendar.current.component(.weekday, from: point.date) - 1
                    ]
                    Text(String(dayLabel.prefix(1)))
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(RTColor.tertiaryText)
                        .position(x: x, y: geo.size.height - 2)
                }
            }
        }
    }

    private var bedtimeChart: some View {
        let bedtimeData = history.compactMap { item -> (date: Date, minutes: Double)? in
            guard let start = item.sleepStart else { return nil }
            let mins = Double(Calendar.current.component(.hour, from: start) * 60 + Calendar.current.component(.minute, from: start))
            return (item.date, mins)
        }

        return Chart(bedtimeData, id: \.date) { point in
            PointMark(
                x: .value("Date", point.date, unit: .day),
                y: .value("Minutes", point.minutes)
            )
            .foregroundStyle(RTColor.sleep)
            .symbolSize(40)

            LineMark(
                x: .value("Date", point.date, unit: .day),
                y: .value("Minutes", point.minutes)
            )
            .foregroundStyle(RTColor.sleep.opacity(0.5))
            .lineStyle(StrokeStyle(lineWidth: 1.5))
            .interpolationMethod(.catmullRom)
        }
        .frame(height: 100)
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine().foregroundStyle(RTColor.divider)
                AxisValueLabel {
                    if let mins = value.as(Double.self) {
                        let h = Int(mins) / 60
                        let m = Int(mins) % 60
                        Text(String(format: "%02d:%02d", h, m))
                            .font(.system(size: 9))
                            .foregroundStyle(RTColor.secondaryText)
                    }
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

    private func dualColumn(
        label: String,
        score: Double,
        icon: String,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(color)
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
            }

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(Int(score.rounded()))")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
                    .monospacedDigit()
                Text("%")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(RTColor.tertiaryText)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(RTColor.surfaceHighlight)
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(max(0, min(1, score / 100))), height: 6)
                }
            }
            .frame(height: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label) \(Int(score.rounded())) percent")
    }
}
