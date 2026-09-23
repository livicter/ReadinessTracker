import SwiftUI
import Charts

/// Elevates morning check-in `mentalFatigue` + `workloadStress` (1–5) into a
/// Tonight | Baseline dual near Check-in Insights. Feeds cognitive-lag scoring
/// but was buried vs feel/alcohol/stress Insights. CheckInStatusCard wells stay
/// chrome-only — not re-chromed.
struct CognitiveLoadTonightBaselineCard: View {
    let tonight: UserMetadata?
    let history: [(date: Date, fatigue: Double, stress: Double)]

    private var tonightFatigue: Double? {
        tonight.flatMap { $0.mentalFatigue.map(Double.init) }
    }

    private var tonightStress: Double? {
        tonight.flatMap { $0.workloadStress.map(Double.init) }
    }

    private var baseFatigue: Double {
        let values = history.map(\.fatigue).filter { $0 > 0 }
        if values.isEmpty { return tonightFatigue ?? 0 }
        return values.reduce(0, +) / Double(values.count)
    }

    private var baseStress: Double {
        let values = history.map(\.stress).filter { $0 > 0 }
        if values.isEmpty { return tonightStress ?? 0 }
        return values.reduce(0, +) / Double(values.count)
    }

    private var deltaFatigue: Double {
        guard let f = tonightFatigue else { return 0 }
        return f - baseFatigue
    }

    private var status: (label: String, color: Color) {
        guard let f = tonightFatigue else {
            return ("No check-in", RTColor.secondaryText)
        }
        let s = tonightStress ?? 0
        let peak = max(f, s)
        if peak >= 5 { return ("Drained", RTColor.warning) }
        if peak >= 4 { return ("Heavy", RTColor.caution) }
        if peak >= 3 { return ("Loaded", RTColor.good) }
        return ("Clear", RTColor.optimal)
    }

    private var sparklineValues: [Double] {
        Array(history.sorted { $0.date < $1.date }.suffix(7).map(\.fatigue))
    }

    private var chartPoints: [(date: Date, value: Double)] {
        history.sorted { $0.date < $1.date }.map { (date: $0.date, value: $0.fatigue) }
    }

    private var deltaCaption: String {
        guard tonightFatigue != nil else { return "Log morning check-in" }
        let sign = deltaFatigue >= 0 ? "+" : ""
        return String(format: "%@%.1f fatigue vs baseline", sign, deltaFatigue)
    }

    private var stressTonightCaption: String {
        guard let s = tonightStress else { return "Stress —" }
        return String(format: "Stress %.0f/5", s)
    }

    private var stressBaselineCaption: String {
        guard baseStress > 0 else { return "Stress —" }
        return String(format: "Stress %.1f/5 avg", baseStress)
    }

    private let loadColor = Color(hex: "AF52DE")

    var body: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Cognitive Load")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(RTColor.primaryText)

                        Text("Fatigue · stress · \(status.label)")
                            .font(.subheadline)
                            .foregroundStyle(status.color)
                    }

                    Spacer()

                    Text(tonightFatigue.map { String(format: "%.0f/5", $0) } ?? "—")
                        .font(.title2.weight(.bold).monospacedDigit())
                        .foregroundStyle(status.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(status.color.opacity(0.12))
                        .clipShape(Capsule())
                        .accessibilityLabel(
                            tonightFatigue.map { "Mental fatigue \($0) of 5, \(status.label)" }
                                ?? "No check-in"
                        )
                }

                HStack(spacing: 12) {
                    dualColumn(
                        label: "Tonight",
                        valueText: tonightFatigue.map { String(format: "%.0f", $0) } ?? "—",
                        unit: "/5",
                        color: status.color,
                        caption: stressTonightCaption,
                        icon: "brain.head.profile"
                    )

                    Rectangle()
                        .fill(RTColor.divider)
                        .frame(width: 1)
                        .padding(.vertical, 4)

                    dualColumn(
                        label: "Baseline",
                        valueText: baseFatigue > 0 ? String(format: "%.1f", baseFatigue) : "—",
                        unit: "/5",
                        color: RTColor.secondaryText,
                        caption: stressBaselineCaption,
                        icon: "chart.line.flattrend.xyaxis"
                    )
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier(SurfaceID.cognitiveLoadBaselineCallout)

                if sparklineValues.count >= 2 {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("7-Day Mental Fatigue")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(RTColor.secondaryText)
                            Spacer()
                            Text(deltaCaption)
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(deltaFatigue >= 1 ? RTColor.caution : RTColor.optimal)
                                .monospacedDigit()
                        }
                        AnimatedSparkline(data: sparklineValues, color: loadColor)
                            .frame(height: 28)
                            .accessibilityIdentifier(SurfaceID.cognitiveLoadSpark)
                    }
                }

                if chartPoints.count >= 3 {
                    Chart {
                        ForEach(Array(chartPoints.enumerated()), id: \.offset) { _, point in
                            LineMark(
                                x: .value("Day", point.date),
                                y: .value("Fatigue", point.value)
                            )
                            .foregroundStyle(loadColor)
                            .interpolationMethod(.catmullRom)

                            AreaMark(
                                x: .value("Day", point.date),
                                y: .value("Fatigue", point.value)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [loadColor.opacity(0.22), loadColor.opacity(0)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .interpolationMethod(.catmullRom)
                        }

                        RuleMark(y: .value("Heavy", 4))
                            .foregroundStyle(RTColor.secondaryText.opacity(0.35))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    }
                    .chartYScale(domain: 0...5)
                    .chartXAxis(.hidden)
                    .chartYAxis {
                        AxisMarks(position: .leading, values: [1, 3, 5]) { value in
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
                    .accessibilityLabel("Mental fatigue trend last seven days")
                }
            }
            .padding(16)
        }
        .accessibilityIdentifier(SurfaceID.cognitiveLoadCard)
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
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

enum CognitiveLoadBaseline {
    /// Morning fatigue + stress history for spark / baseline.
    @MainActor
    static func history(from store: MetadataStore, days: Int = 14) -> [(date: Date, fatigue: Double, stress: Double)] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<days).compactMap { offset -> (Date, Double, Double)? in
            guard let date = cal.date(byAdding: .day, value: -offset, to: today),
                  let meta = store.metadataFor(date: date, timeOfDay: .morning),
                  let fatigue = meta.mentalFatigue else { return nil }
            let stress = Double(meta.workloadStress ?? 0)
            return (date, Double(fatigue), stress)
        }
    }
}
