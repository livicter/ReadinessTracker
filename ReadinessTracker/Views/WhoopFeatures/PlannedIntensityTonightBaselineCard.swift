import SwiftUI
import Charts

/// Elevates evening check-in `plannedWorkoutIntensity` (Light/Moderate/Heavy)
/// into a Tonight | Baseline dual near Workout RPE — tomorrow’s load plan was
/// unused on Today. CheckInStatusCard wells stay chrome-only — not re-chromed.
struct PlannedIntensityTonightBaselineCard: View {
    let tonight: UserMetadata?
    let history: [(date: Date, score: Double, label: String)]

    private var tonightScore: Double? {
        guard let meta = tonight, meta.plannedWorkoutTomorrow,
              let raw = meta.plannedWorkoutIntensity,
              let score = PlannedIntensityBaseline.score(from: raw) else { return nil }
        return score
    }

    private var tonightLabel: String? {
        guard let meta = tonight, meta.plannedWorkoutTomorrow,
              let raw = meta.plannedWorkoutIntensity else { return nil }
        return PlannedIntensityBaseline.canonical(raw)
    }

    private var base: Double {
        let values = history.map(\.score).filter { $0 > 0 }
        if values.isEmpty { return tonightScore ?? 0 }
        return values.reduce(0, +) / Double(values.count)
    }

    private var baseLabel: String {
        PlannedIntensityBaseline.label(for: base)
    }

    private var delta: Double {
        guard let s = tonightScore else { return 0 }
        return s - base
    }

    private var status: (label: String, color: Color) {
        guard let score = tonightScore, let name = tonightLabel else {
            if tonight?.plannedWorkoutTomorrow == false {
                return ("Rest planned", RTColor.secondaryText)
            }
            return ("No evening plan", RTColor.secondaryText)
        }
        if score >= 3 { return ("Heavy · \(name)", RTColor.warning) }
        if score >= 2 { return ("Moderate · \(name)", RTColor.caution) }
        return ("Light · \(name)", RTColor.optimal)
    }

    private var sparklineValues: [Double] {
        Array(history.sorted { $0.date < $1.date }.suffix(7).map(\.score))
    }

    private var chartPoints: [(date: Date, value: Double)] {
        history.sorted { $0.date < $1.date }.map { (date: $0.date, value: $0.score) }
    }

    private var deltaCaption: String {
        guard tonightScore != nil else { return "Log evening plan" }
        let sign = delta >= 0 ? "+" : ""
        return String(format: "%@%.1f vs baseline", sign, delta)
    }

    private var typeCaption: String {
        guard let meta = tonight else { return "No check-in" }
        if !meta.plannedWorkoutTomorrow { return "No workout planned" }
        if let t = meta.plannedWorkoutType, !t.isEmpty { return t }
        return "Workout planned"
    }

    private let planColor = Color(hex: "0A84FF")

    var body: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Tomorrow's Plan")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(RTColor.primaryText)

                        Text("Intensity · \(status.label)")
                            .font(.subheadline)
                            .foregroundStyle(status.color)
                    }

                    Spacer()

                    Text(tonightLabel ?? "—")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(status.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(status.color.opacity(0.12))
                        .clipShape(Capsule())
                        .accessibilityLabel(
                            tonightLabel.map { "Planned intensity \($0), \(status.label)" } ?? status.label
                        )
                }

                HStack(spacing: 12) {
                    dualColumn(
                        label: "Tonight",
                        valueText: tonightScore.map { String(format: "%.0f", $0) } ?? "—",
                        unit: "/3",
                        color: status.color,
                        caption: typeCaption,
                        icon: "calendar"
                    )

                    Rectangle()
                        .fill(RTColor.divider)
                        .frame(width: 1)
                        .padding(.vertical, 4)

                    dualColumn(
                        label: "Baseline",
                        valueText: base > 0 ? String(format: "%.1f", base) : "—",
                        unit: "/3",
                        color: RTColor.secondaryText,
                        caption: base > 0 ? "\(baseLabel) · 7-day avg" : "No plan history",
                        icon: "chart.line.uptrend.xyaxis"
                    )
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier(SurfaceID.plannedIntensityBaselineCallout)

                if sparklineValues.count >= 2 {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("7-Day Planned Intensity")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(RTColor.secondaryText)
                            Spacer()
                            Text(deltaCaption)
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(delta >= 0.75 ? RTColor.caution : RTColor.optimal)
                                .monospacedDigit()
                        }
                        AnimatedSparkline(data: sparklineValues, color: planColor)
                            .frame(height: 28)
                            .accessibilityIdentifier(SurfaceID.plannedIntensitySpark)
                    }
                }

                if chartPoints.count >= 3 {
                    Chart {
                        ForEach(Array(chartPoints.enumerated()), id: \.offset) { _, point in
                            LineMark(
                                x: .value("Day", point.date),
                                y: .value("Intensity", point.value)
                            )
                            .foregroundStyle(planColor)
                            .interpolationMethod(.catmullRom)

                            AreaMark(
                                x: .value("Day", point.date),
                                y: .value("Intensity", point.value)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [planColor.opacity(0.22), planColor.opacity(0)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .interpolationMethod(.catmullRom)
                        }

                        RuleMark(y: .value("Heavy", 3))
                            .foregroundStyle(RTColor.secondaryText.opacity(0.35))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    }
                    .chartYScale(domain: 0...3.5)
                    .chartXAxis(.hidden)
                    .chartYAxis {
                        AxisMarks(position: .leading, values: [1, 2, 3]) { value in
                            AxisGridLine()
                            AxisValueLabel {
                                if let v = value.as(Double.self) {
                                    Text(PlannedIntensityBaseline.label(for: v))
                                        .font(.caption2)
                                        .foregroundStyle(RTColor.secondaryText)
                                }
                            }
                        }
                    }
                    .frame(height: 88)
                    .accessibilityLabel("Planned workout intensity trend last seven days")
                }
            }
            .padding(16)
        }
        .accessibilityIdentifier(SurfaceID.plannedIntensityCard)
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

enum PlannedIntensityBaseline {
    static func score(from raw: String) -> Double? {
        switch raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "light": return 1
        case "moderate": return 2
        case "heavy": return 3
        default: return nil
        }
    }

    static func canonical(_ raw: String) -> String {
        switch raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "light": return "Light"
        case "moderate": return "Moderate"
        case "heavy": return "Heavy"
        default: return raw
        }
    }

    static func label(for score: Double) -> String {
        if score >= 2.5 { return "Heavy" }
        if score >= 1.5 { return "Moderate" }
        if score > 0 { return "Light" }
        return "—"
    }

    /// Evening planned-intensity history for spark / baseline (planned days only).
    @MainActor
    static func history(from store: MetadataStore, days: Int = 14) -> [(date: Date, score: Double, label: String)] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<days).compactMap { offset -> (Date, Double, String)? in
            guard let date = cal.date(byAdding: .day, value: -offset, to: today),
                  let meta = store.metadataFor(date: date, timeOfDay: .evening),
                  meta.plannedWorkoutTomorrow,
                  let raw = meta.plannedWorkoutIntensity,
                  let score = score(from: raw) else { return nil }
            return (date, score, canonical(raw))
        }
    }
}
