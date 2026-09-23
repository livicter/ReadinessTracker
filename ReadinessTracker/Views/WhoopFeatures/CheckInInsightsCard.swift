import SwiftUI
import Charts

/// Elevates buried check-in tags (feel, alcohol, stress) into a Tonight | Baseline
/// dual on Today. CheckInStatusCard (#72) stays Morning/Evening Done wells — not
/// re-chromed. Reads `UserMetadata` morning entries via MetadataStore.
struct CheckInInsightsCard: View {
    let tonight: UserMetadata?
    let history: [(date: Date, feel: Double, drinks: Int, stressed: Bool)]

    private var tonightFeel: Double? {
        tonight.flatMap { meta in meta.subjectiveFeel.map(Double.init) }
    }

    private var baseFeel: Double {
        let values = history.map(\.feel).filter { $0 > 0 }
        if values.isEmpty { return tonightFeel ?? 0 }
        return values.reduce(0, +) / Double(values.count)
    }

    private var tonightDrinks: Int {
        tonight?.alcoholConsumed == true ? (tonight?.alcoholDrinks ?? 0) : 0
    }

    private var tonightStressed: Bool { tonight?.isStressed == true }

    private var deltaFeel: Double {
        guard let feel = tonightFeel else { return 0 }
        return feel - baseFeel
    }

    private var status: (label: String, color: Color) {
        guard let feel = tonightFeel else {
            return ("No check-in", RTColor.secondaryText)
        }
        if tonightDrinks >= 3 || (tonightStressed && feel <= 2) {
            return ("Flagged", RTColor.warning)
        }
        if tonightDrinks >= 1 || tonightStressed || feel <= 2 {
            return ("Watch", RTColor.caution)
        }
        if feel >= 4 { return ("Strong", RTColor.optimal) }
        return ("Steady", RTColor.good)
    }

    private var sparklineValues: [Double] {
        Array(history.sorted { $0.date < $1.date }.suffix(7).map(\.feel))
    }

    private var chartPoints: [(date: Date, value: Double)] {
        history.sorted { $0.date < $1.date }.map { (date: $0.date, value: $0.feel) }
    }

    private var deltaCaption: String {
        guard tonightFeel != nil else { return "Log morning check-in" }
        let sign = deltaFeel >= 0 ? "+" : ""
        return String(format: "%@%.1f vs baseline", sign, deltaFeel)
    }

    private var tagsCaption: String {
        var parts: [String] = []
        if tonightDrinks > 0 {
            parts.append("\(tonightDrinks) drink\(tonightDrinks == 1 ? "" : "s")")
        }
        if tonightStressed { parts.append("Stressed") }
        if tonight?.isSick == true { parts.append("Sick") }
        if tonight?.caffeineAfter2pm == true { parts.append("Late caffeine") }
        return parts.isEmpty ? "No lifestyle flags" : parts.joined(separator: " · ")
    }

    var body: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Check-in Insights")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(RTColor.primaryText)

                        Text("Feel · alcohol · stress · \(status.label)")
                            .font(.subheadline)
                            .foregroundStyle(status.color)
                    }

                    Spacer()

                    Text(tonightFeel.map { String(format: "%.0f/5", $0) } ?? "—")
                        .font(.title2.weight(.bold).monospacedDigit())
                        .foregroundStyle(status.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(status.color.opacity(0.12))
                        .clipShape(Capsule())
                        .accessibilityLabel(
                            tonightFeel.map { "Feel \($0) of 5, \(status.label)" } ?? "No check-in"
                        )
                }

                HStack(spacing: 12) {
                    dualColumn(
                        label: "Tonight",
                        valueText: tonightFeel.map { String(format: "%.0f", $0) } ?? "—",
                        unit: "/5",
                        color: status.color,
                        caption: tagsCaption,
                        icon: "face.smiling"
                    )

                    Rectangle()
                        .fill(RTColor.divider)
                        .frame(width: 1)
                        .padding(.vertical, 4)

                    dualColumn(
                        label: "Baseline",
                        valueText: baseFeel > 0 ? String(format: "%.1f", baseFeel) : "—",
                        unit: "/5",
                        color: RTColor.secondaryText,
                        caption: "7-day feel average",
                        icon: "chart.line.flattrend.xyaxis"
                    )
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier(SurfaceID.checkInInsightsBaselineCallout)

                if sparklineValues.count >= 2 {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("7-Day Feel")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(RTColor.secondaryText)
                            Spacer()
                            Text(deltaCaption)
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(deltaFeel < -0.5 ? RTColor.caution : RTColor.optimal)
                                .monospacedDigit()
                        }
                        AnimatedSparkline(data: sparklineValues, color: RTColor.optimal)
                            .frame(height: 28)
                            .accessibilityIdentifier(SurfaceID.checkInInsightsSpark)
                    }
                }

                if chartPoints.count >= 3 {
                    Chart {
                        ForEach(Array(chartPoints.enumerated()), id: \.offset) { _, point in
                            LineMark(
                                x: .value("Day", point.date),
                                y: .value("Feel", point.value)
                            )
                            .foregroundStyle(RTColor.optimal)
                            .interpolationMethod(.catmullRom)

                            AreaMark(
                                x: .value("Day", point.date),
                                y: .value("Feel", point.value)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [RTColor.optimal.opacity(0.18), RTColor.optimal.opacity(0)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .interpolationMethod(.catmullRom)
                        }

                        RuleMark(y: .value("Steady", 3))
                            .foregroundStyle(RTColor.secondaryText.opacity(0.35))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    }
                    .chartYScale(domain: 1...5)
                    .chartXAxis(.hidden)
                    .chartYAxis {
                        AxisMarks(position: .leading, values: [2, 3, 4]) { value in
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
                    .accessibilityLabel("Subjective feel trend last seven days")
                }
            }
            .padding(16)
        }
        .accessibilityIdentifier(SurfaceID.checkInInsightsCard)
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
            HStack(alignment: .firstTextBaseline, spacing: 2) {
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
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

enum CheckInInsights {
    /// Morning feel history for spark / baseline (newest-first store → sorted by date).
    @MainActor
    static func feelHistory(from store: MetadataStore, days: Int = 14) -> [(date: Date, feel: Double, drinks: Int, stressed: Bool)] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<days).compactMap { offset -> (Date, Double, Int, Bool)? in
            guard let date = cal.date(byAdding: .day, value: -offset, to: today),
                  let meta = store.metadataFor(date: date, timeOfDay: .morning),
                  let feel = meta.subjectiveFeel else { return nil }
            let drinks = meta.alcoholConsumed ? (meta.alcoholDrinks ?? 0) : 0
            return (date, Double(feel), drinks, meta.isStressed)
        }
    }
}
