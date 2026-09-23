import SwiftUI
import Charts

/// WHOOP-style daily training load: Tonight vs Baseline dual callout from
/// summed `strainSessions.trimp`. Complements Workout Minutes (duration) and
/// WorkoutSummaryCard’s per-session TRIMP chips without re-chroming the list.
struct DailyTRIMPCard: View {
    let sessions: [StrainSession]
    let history: [(date: Date, trimp: Double)]
    let baseline: Double

    private var tonight: Double {
        DailyTRIMP.total(from: sessions)
    }

    private var base: Double {
        let b = baseline > 0 ? baseline : tonight
        return max(0, b)
    }

    private var delta: Double { tonight - base }

    private var sessionCount: Int { sessions.count }

    private var status: (label: String, color: Color) {
        // Mirrors WorkoutSummaryCard load bands (High ≥120, Solid ≥60).
        if tonight >= 120 { return ("High load", RTColor.caution) }
        if tonight >= 60 { return ("Solid", RTColor.good) }
        if tonight >= 25 { return ("Light", RTColor.optimal) }
        return ("Rest", RTColor.secondaryText)
    }

    private var sparklineValues: [Double] {
        let sorted = history.sorted { $0.date < $1.date }
        return Array(sorted.suffix(7).map(\.trimp))
    }

    private var chartPoints: [(date: Date, value: Double)] {
        history.sorted { $0.date < $1.date }.map { (date: $0.date, value: $0.trimp) }
    }

    private var deltaCaption: String {
        let sign = delta >= 0 ? "+" : ""
        return "\(sign)\(Int(delta.rounded())) vs baseline"
    }

    private var sessionsCaption: String {
        if sessionCount == 0 { return "No sessions" }
        return sessionCount == 1 ? "1 session" : "\(sessionCount) sessions"
    }

    var body: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Daily TRIMP")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(RTColor.primaryText)

                        Text("Session load · \(status.label)")
                            .font(.subheadline)
                            .foregroundStyle(status.color)
                    }

                    Spacer()

                    Text("\(Int(tonight.rounded()))")
                        .font(.title2.weight(.bold).monospacedDigit())
                        .foregroundStyle(status.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(status.color.opacity(0.12))
                        .clipShape(Capsule())
                        .accessibilityLabel("\(Int(tonight.rounded())) TRIMP, \(status.label)")
                }

                HStack(spacing: 12) {
                    dualColumn(
                        label: "Tonight",
                        valueText: "\(Int(tonight.rounded()))",
                        unit: "TRIMP",
                        color: status.color,
                        caption: sessionsCaption,
                        icon: "bolt.heart.fill"
                    )

                    Rectangle()
                        .fill(RTColor.divider)
                        .frame(width: 1)
                        .padding(.vertical, 4)

                    dualColumn(
                        label: "Baseline",
                        valueText: "\(Int(base.rounded()))",
                        unit: "TRIMP",
                        color: RTColor.secondaryText,
                        caption: "7-day average",
                        icon: "chart.line.flattrend.xyaxis"
                    )
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier(SurfaceID.dailyTRIMPBaselineCallout)

                if sparklineValues.count >= 2 {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("7-Day TRIMP")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(RTColor.secondaryText)
                            Spacer()
                            Text(deltaCaption)
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(delta > 30 ? RTColor.caution : RTColor.optimal)
                                .monospacedDigit()
                        }
                        AnimatedSparkline(data: sparklineValues, color: RTColor.strain)
                            .frame(height: 28)
                            .accessibilityIdentifier(SurfaceID.dailyTRIMPSpark)
                    }
                }

                if chartPoints.count >= 3 {
                    Chart {
                        ForEach(Array(chartPoints.enumerated()), id: \.offset) { _, point in
                            LineMark(
                                x: .value("Day", point.date),
                                y: .value("TRIMP", point.value)
                            )
                            .foregroundStyle(RTColor.strain)
                            .interpolationMethod(.catmullRom)

                            AreaMark(
                                x: .value("Day", point.date),
                                y: .value("TRIMP", point.value)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [RTColor.strain.opacity(0.18), RTColor.strain.opacity(0)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .interpolationMethod(.catmullRom)
                        }

                        RuleMark(y: .value("Solid", 60))
                            .foregroundStyle(RTColor.secondaryText.opacity(0.35))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    }
                    .chartYScale(domain: 0...(max(140.0, (chartPoints.map(\.value).max() ?? 80) * 1.2)))
                    .chartXAxis(.hidden)
                    .chartYAxis {
                        AxisMarks(position: .leading, values: [30, 60, 120]) { value in
                            AxisGridLine()
                            AxisValueLabel {
                                if let v = value.as(Double.self) {
                                    Text("\(Int(v))")
                                        .font(.caption2)
                                        .foregroundStyle(RTColor.secondaryText)
                                }
                            }
                        }
                    }
                    .frame(height: 88)
                    .accessibilityLabel("Daily TRIMP trend last days")
                }
            }
            .padding(16)
        }
        .accessibilityIdentifier(SurfaceID.dailyTRIMPCard)
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
                    .font(.title2.weight(.bold).monospacedDigit())
                    .foregroundStyle(RTColor.primaryText)
                Text(unit)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(RTColor.secondaryText)
            }
            Text(caption)
                .font(.caption2)
                .foregroundStyle(RTColor.secondaryText)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

enum DailyTRIMP {
    static func total(from sessions: [StrainSession]) -> Double {
        max(0, sessions.map(\.trimp).reduce(0, +))
    }

    static func baseline(
        from history: [DailyHealthData],
        window: Int = 7,
        fallback: Double
    ) -> Double {
        let values = history
            .sorted { $0.date > $1.date }
            .prefix(window)
            .map { total(from: $0.strainSessions) }
        guard !values.isEmpty else { return fallback }
        return values.reduce(0, +) / Double(values.count)
    }
}
