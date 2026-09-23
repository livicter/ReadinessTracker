import SwiftUI
import Charts

/// WHOOP / Apple Health–style sleep midpoint: Tonight vs Baseline dual callout,
/// Early / Intermediate / Late chronotype band, and a compact 7-night sparkline.
/// Elevates unused `sleepStartTime` / `sleepEndTime` into a glanceable timing card.
struct SleepMidpointCard: View {
    /// Midpoint as minutes from local midnight (0…1439).
    let currentMinutes: Double
    let history: [(date: Date, minutes: Double)]
    let baseline: Double

    private var tonight: Double {
        var m = currentMinutes.truncatingRemainder(dividingBy: 1440)
        if m < 0 { m += 1440 }
        return m
    }

    private var base: Double {
        var b = (baseline > 0 ? baseline : tonight).truncatingRemainder(dividingBy: 1440)
        if b < 0 { b += 1440 }
        return b
    }

    /// Signed delta in minutes (−720…+720), wrapping across midnight.
    private var deltaMinutes: Double {
        var d = tonight - base
        if d > 720 { d -= 1440 }
        if d < -720 { d += 1440 }
        return d
    }

    private var status: (label: String, color: Color) {
        // Absolute chronotype from midpoint clock time (Munich-style bands).
        if tonight < 3 * 60 { return ("Early", RTColor.optimal) }
        if tonight < 5 * 60 { return ("Intermediate", RTColor.good) }
        return ("Late", RTColor.caution)
    }

    private var sparklineValues: [Double] {
        let sorted = history.sorted { $0.date < $1.date }
        return Array(sorted.suffix(7).map(\.minutes))
    }

    private var chartPoints: [(date: Date, value: Double)] {
        history.sorted { $0.date < $1.date }.map { (date: $0.date, value: $0.minutes) }
    }

    private var deltaCaption: String {
        let mins = Int(deltaMinutes.rounded())
        if mins == 0 { return "On baseline" }
        let sign = mins > 0 ? "+" : ""
        return "\(sign)\(mins) min vs baseline"
    }

    private func clockLabel(_ minutes: Double) -> String {
        var m = Int(minutes.rounded()) % 1440
        if m < 0 { m += 1440 }
        let h24 = m / 60
        let min = m % 60
        let period = h24 >= 12 ? "PM" : "AM"
        var h12 = h24 % 12
        if h12 == 0 { h12 = 12 }
        return String(format: "%d:%02d %@", h12, min, period)
    }

    var body: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sleep Midpoint")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(RTColor.primaryText)

                        Text("Chronotype · \(status.label)")
                            .font(.subheadline)
                            .foregroundStyle(status.color)
                    }

                    Spacer()

                    Text(clockLabel(tonight))
                        .font(.title3.weight(.bold).monospacedDigit())
                        .foregroundStyle(status.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(status.color.opacity(0.12))
                        .clipShape(Capsule())
                        .accessibilityLabel("Sleep midpoint \(clockLabel(tonight)), \(status.label)")
                }

                HStack(spacing: 12) {
                    dualColumn(
                        label: "Tonight",
                        valueText: clockLabel(tonight),
                        unit: "",
                        color: status.color,
                        caption: deltaCaption,
                        icon: "moon.stars.fill"
                    )

                    Rectangle()
                        .fill(RTColor.divider)
                        .frame(width: 1)
                        .padding(.vertical, 4)

                    dualColumn(
                        label: "Baseline",
                        valueText: clockLabel(base),
                        unit: "",
                        color: RTColor.secondaryText,
                        caption: "7-night average",
                        icon: "chart.line.flattrend.xyaxis"
                    )
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier(SurfaceID.sleepMidpointBaselineCallout)

                if sparklineValues.count >= 2 {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("7-Night Midpoint")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(RTColor.secondaryText)
                            Spacer()
                            Text(deltaCaption)
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(abs(deltaMinutes) > 30 ? RTColor.warning : RTColor.optimal)
                                .monospacedDigit()
                        }
                        AnimatedSparkline(data: sparklineValues, color: RTColor.sleep)
                            .frame(height: 28)
                            .accessibilityIdentifier(SurfaceID.sleepMidpointSpark)
                    }
                }

                if chartPoints.count >= 3 {
                    Chart {
                        ForEach(Array(chartPoints.enumerated()), id: \.offset) { _, point in
                            LineMark(
                                x: .value("Night", point.date),
                                y: .value("Minutes", point.value)
                            )
                            .foregroundStyle(RTColor.sleep)
                            .interpolationMethod(.catmullRom)

                            AreaMark(
                                x: .value("Night", point.date),
                                y: .value("Minutes", point.value)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [RTColor.sleep.opacity(0.18), RTColor.sleep.opacity(0)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .interpolationMethod(.catmullRom)
                        }

                        RuleMark(y: .value("Intermediate", 4 * 60))
                            .foregroundStyle(RTColor.secondaryText.opacity(0.35))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    }
                    .chartYScale(domain: yDomain)
                    .chartXAxis(.hidden)
                    .chartYAxis {
                        AxisMarks(position: .leading, values: yAxisMarks) { value in
                            AxisGridLine()
                            AxisValueLabel {
                                if let v = value.as(Double.self) {
                                    Text(shortClock(v))
                                        .font(.caption2)
                                        .foregroundStyle(RTColor.secondaryText)
                                }
                            }
                        }
                    }
                    .frame(height: 88)
                    .accessibilityLabel("Sleep midpoint trend last nights")
                }
            }
            .padding(16)
        }
        .accessibilityIdentifier(SurfaceID.sleepMidpointCard)
    }

    private var yDomain: ClosedRange<Double> {
        let vals = chartPoints.map(\.value) + [tonight, base, 180, 300]
        let lo = max(0, (vals.min() ?? 120) - 30)
        let hi = min(720, (vals.max() ?? 360) + 30)
        return lo...max(hi, lo + 60)
    }

    private var yAxisMarks: [Double] {
        let mid = (yDomain.lowerBound + yDomain.upperBound) / 2
        return [yDomain.lowerBound, mid, yDomain.upperBound].map { ($0 / 30).rounded() * 30 }
    }

    private func shortClock(_ minutes: Double) -> String {
        var m = Int(minutes.rounded()) % 1440
        if m < 0 { m += 1440 }
        let h24 = m / 60
        let min = m % 60
        return String(format: "%d:%02d", h24, min)
    }

    private func dualColumn(
        label: String,
        valueText: String,
        unit: String,
        color: Color,
        caption: String,
        icon: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(color)
                    .frame(width: 22, height: 22)
                    .background(color.opacity(0.12))
                    .clipShape(Circle())
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
            }
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(valueText)
                    .font(.title3.weight(.bold).monospacedDigit())
                    .foregroundStyle(RTColor.primaryText)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(RTColor.secondaryText)
                }
            }
            Text(caption)
                .font(.caption2)
                .foregroundStyle(RTColor.secondaryText)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Midpoint helpers (shared with Dashboard fixture wiring)

enum SleepMidpoint {
    /// Midpoint clock minutes from local midnight, or nil if times missing / inverted.
    static func minutes(start: Date?, end: Date?) -> Double? {
        guard let start, let end, end > start else { return nil }
        let mid = start.addingTimeInterval(end.timeIntervalSince(start) / 2.0)
        let cal = Calendar.current
        let h = cal.component(.hour, from: mid)
        let m = cal.component(.minute, from: mid)
        return Double(h * 60 + m)
    }

    /// Circular mean of midpoint minutes (handles wrap near midnight).
    static func baseline(from samples: [Double], fallback: Double) -> Double {
        let vals = samples.filter { $0 >= 0 && $0 < 1440 }
        guard !vals.isEmpty else { return fallback }
        // Sleep midpoints cluster 01:00–06:00 — plain mean is stable; keep circular for safety.
        let angles = vals.map { $0 / 1440.0 * 2.0 * Double.pi }
        let sinSum = angles.map(sin).reduce(0, +)
        let cosSum = angles.map(cos).reduce(0, +)
        guard hypot(sinSum, cosSum) > 1e-9 else { return fallback }
        var mean = atan2(sinSum, cosSum)
        if mean < 0 { mean += 2.0 * Double.pi }
        return mean / (2.0 * Double.pi) * 1440.0
    }
}
