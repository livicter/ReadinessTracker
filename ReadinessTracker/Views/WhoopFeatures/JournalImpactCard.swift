import SwiftUI
import Charts

/// Elevates Journal Behavior Impact onto Today as Tonight | Baseline.
/// JournalView’s Behavior Impact list (#82 circular wells) stays as the deep dive —
/// not re-chromed. Reads the same `journal_entries` store / UIFixture seed.
struct JournalImpactCard: View {
    let entries: [JournalEntry]

    private var todayEntry: JournalEntry? {
        let cal = Calendar.current
        return entries.first { cal.isDateInToday($0.date) }
    }

    private var scoredEntries: [(date: Date, score: Double, behaviors: [JournalEntryView.Behavior])] {
        entries.compactMap { entry in
            guard let score = entry.readinessScore else { return nil }
            return (entry.date, Double(score), entry.behaviors)
        }
    }

    private var tonightScore: Double? {
        todayEntry.flatMap { $0.readinessScore.map(Double.init) }
    }

    private var baselineScore: Double {
        let values = scoredEntries.map(\.score)
        guard !values.isEmpty else { return tonightScore ?? 0 }
        return values.reduce(0, +) / Double(values.count)
    }

    private var delta: Double {
        guard let tonight = tonightScore else { return 0 }
        return tonight - baselineScore
    }

    private var tonightTags: [JournalEntryView.Behavior] {
        todayEntry?.behaviors ?? []
    }

    private var dragCount: Int {
        tonightTags.filter { $0.category != "Recovery" }.count
    }

    private var recoveryCount: Int {
        tonightTags.filter { $0.category == "Recovery" }.count
    }

    private var status: (label: String, color: Color) {
        guard tonightScore != nil else { return ("No entry", RTColor.secondaryText) }
        if dragCount > 0 && recoveryCount == 0 { return ("Drag day", RTColor.warning) }
        if dragCount > 0 { return ("Mixed", RTColor.caution) }
        if recoveryCount > 0 { return ("Recovery", RTColor.optimal) }
        if let s = tonightScore, s >= 75 { return ("Strong", RTColor.good) }
        return ("Steady", RTColor.good)
    }

    private var sparklineValues: [Double] {
        Array(scoredEntries.sorted { $0.date < $1.date }.suffix(7).map(\.score))
    }

    private var chartPoints: [(date: Date, value: Double)] {
        scoredEntries.sorted { $0.date < $1.date }.map { (date: $0.date, value: $0.score) }
    }

    private var tagsCaption: String {
        if tonightTags.isEmpty { return "Log behaviors in Journal" }
        return tonightTags.map(\.rawValue).joined(separator: " · ")
    }

    private var deltaCaption: String {
        guard tonightScore != nil else { return "Add today’s journal" }
        let sign = delta >= 0 ? "+" : ""
        return String(format: "%@%.0f vs journal avg", sign, delta)
    }

    var body: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Journal Impact")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(RTColor.primaryText)

                        Text("Behaviors · readiness · \(status.label)")
                            .font(.subheadline)
                            .foregroundStyle(status.color)
                    }

                    Spacer()

                    Text(tonightScore.map { "\(Int($0.rounded()))" } ?? "—")
                        .font(.title2.weight(.bold).monospacedDigit())
                        .foregroundStyle(status.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(status.color.opacity(0.12))
                        .clipShape(Capsule())
                        .accessibilityLabel(
                            tonightScore.map { "Tonight readiness \(Int($0.rounded())), \(status.label)" }
                                ?? "No journal entry tonight"
                        )
                }

                HStack(spacing: 12) {
                    dualColumn(
                        label: "Tonight",
                        valueText: tonightScore.map { "\(Int($0.rounded()))" } ?? "—",
                        unit: "",
                        color: status.color,
                        caption: tagsCaption,
                        icon: "book.closed.fill"
                    )

                    Rectangle()
                        .fill(RTColor.divider)
                        .frame(width: 1)
                        .padding(.vertical, 4)

                    dualColumn(
                        label: "Baseline",
                        valueText: baselineScore > 0 ? "\(Int(baselineScore.rounded()))" : "—",
                        unit: "",
                        color: RTColor.secondaryText,
                        caption: "journal-day avg",
                        icon: "chart.line.uptrend.xyaxis"
                    )
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier(SurfaceID.journalImpactBaselineCallout)

                if sparklineValues.count >= 2 {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("7-Day Journal")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(RTColor.secondaryText)
                            Spacer()
                            Text(deltaCaption)
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(delta < -8 ? RTColor.caution : RTColor.optimal)
                                .monospacedDigit()
                        }
                        AnimatedSparkline(data: sparklineValues, color: RTColor.optimal)
                            .frame(height: 28)
                            .accessibilityIdentifier(SurfaceID.journalImpactSpark)
                    }
                }

                if chartPoints.count >= 3 {
                    Chart {
                        ForEach(Array(chartPoints.enumerated()), id: \.offset) { _, point in
                            LineMark(
                                x: .value("Day", point.date),
                                y: .value("Score", point.value)
                            )
                            .foregroundStyle(RTColor.optimal)
                            .interpolationMethod(.catmullRom)

                            AreaMark(
                                x: .value("Day", point.date),
                                y: .value("Score", point.value)
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

                        RuleMark(y: .value("Good", 70))
                            .foregroundStyle(RTColor.secondaryText.opacity(0.35))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    }
                    .chartYScale(domain: 30...100)
                    .chartXAxis(.hidden)
                    .chartYAxis {
                        AxisMarks(position: .leading, values: [50, 70, 90]) { value in
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
                    .accessibilityLabel("Journal readiness trend last days")
                }
            }
            .padding(16)
        }
        .accessibilityIdentifier(SurfaceID.journalImpactCard)
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
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

enum JournalImpact {
    static let entriesKey = "journal_entries"

    static func loadEntries() -> [JournalEntry] {
        guard let data = UserDefaults.standard.data(forKey: entriesKey),
              let decoded = try? JSONDecoder().decode([JournalEntry].self, from: data) else {
            return []
        }
        return decoded
    }
}
