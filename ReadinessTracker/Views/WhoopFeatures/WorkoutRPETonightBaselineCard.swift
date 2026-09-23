import SwiftUI
import Charts

/// Elevates evening check-in `workoutRPE` (1–10) into a Tonight | Baseline dual
/// near Check-in Insights. CheckInStatusCard Morning/Evening Done wells stay
/// chrome-only — not re-chromed. Complements Daily TRIMP (objective load) with
/// subjective session hard-ness from MetadataStore.
struct WorkoutRPETonightBaselineCard: View {
    let tonight: UserMetadata?
    let history: [(date: Date, rpe: Double)]

    private var tonightRPE: Double? {
        guard let meta = tonight, meta.workoutToday, let rpe = meta.workoutRPE else { return nil }
        return Double(rpe)
    }

    private var base: Double {
        let values = history.map(\.rpe).filter { $0 > 0 }
        if values.isEmpty { return tonightRPE ?? 0 }
        return values.reduce(0, +) / Double(values.count)
    }

    private var delta: Double {
        guard let rpe = tonightRPE else { return 0 }
        return rpe - base
    }

    private var status: (label: String, color: Color) {
        guard let rpe = tonightRPE else {
            if tonight?.workoutToday == false {
                return ("Rest day", RTColor.secondaryText)
            }
            return ("No evening log", RTColor.secondaryText)
        }
        if rpe >= 8 { return ("Very hard", RTColor.warning) }
        if rpe >= 7 { return ("Hard", RTColor.caution) }
        if rpe >= 5 { return ("Moderate", RTColor.good) }
        return ("Easy", RTColor.optimal)
    }

    private var sparklineValues: [Double] {
        Array(history.sorted { $0.date < $1.date }.suffix(7).map(\.rpe))
    }

    private var chartPoints: [(date: Date, value: Double)] {
        history.sorted { $0.date < $1.date }.map { (date: $0.date, value: $0.rpe) }
    }

    private var deltaCaption: String {
        guard tonightRPE != nil else { return "Log evening check-in" }
        let sign = delta >= 0 ? "+" : ""
        return String(format: "%@%.1f vs baseline", sign, delta)
    }

    private var typeCaption: String {
        guard let meta = tonight else { return "No check-in" }
        if !meta.workoutToday { return "No workout logged" }
        var parts: [String] = []
        if let t = meta.workoutType, !t.isEmpty { parts.append(t) }
        if let mins = meta.workoutDurationMinutes { parts.append("\(mins) min") }
        return parts.isEmpty ? "Workout logged" : parts.joined(separator: " · ")
    }

    private let rpeColor = Color(hex: "FF9F0A")

    var body: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Workout RPE")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(RTColor.primaryText)

                        Text("Session hard · \(status.label)")
                            .font(.subheadline)
                            .foregroundStyle(status.color)
                    }

                    Spacer()

                    Text(tonightRPE.map { String(format: "%.0f/10", $0) } ?? "—")
                        .font(.title2.weight(.bold).monospacedDigit())
                        .foregroundStyle(status.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(status.color.opacity(0.12))
                        .clipShape(Capsule())
                        .accessibilityLabel(
                            tonightRPE.map { "RPE \($0) of 10, \(status.label)" } ?? status.label
                        )
                }

                HStack(spacing: 12) {
                    dualColumn(
                        label: "Tonight",
                        valueText: tonightRPE.map { String(format: "%.0f", $0) } ?? "—",
                        unit: "/10",
                        color: status.color,
                        caption: typeCaption,
                        icon: "gauge.with.dots.needle.67percent"
                    )

                    Rectangle()
                        .fill(RTColor.divider)
                        .frame(width: 1)
                        .padding(.vertical, 4)

                    dualColumn(
                        label: "Baseline",
                        valueText: base > 0 ? String(format: "%.1f", base) : "—",
                        unit: "/10",
                        color: RTColor.secondaryText,
                        caption: "7-day RPE average",
                        icon: "chart.line.uptrend.xyaxis"
                    )
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier(SurfaceID.workoutRPEBaselineCallout)

                if sparklineValues.count >= 2 {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("7-Day Workout RPE")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(RTColor.secondaryText)
                            Spacer()
                            Text(deltaCaption)
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(delta >= 1.5 ? RTColor.caution : RTColor.optimal)
                                .monospacedDigit()
                        }
                        AnimatedSparkline(data: sparklineValues, color: rpeColor)
                            .frame(height: 28)
                            .accessibilityIdentifier(SurfaceID.workoutRPESpark)
                    }
                }

                if chartPoints.count >= 3 {
                    Chart {
                        ForEach(Array(chartPoints.enumerated()), id: \.offset) { _, point in
                            LineMark(
                                x: .value("Day", point.date),
                                y: .value("RPE", point.value)
                            )
                            .foregroundStyle(rpeColor)
                            .interpolationMethod(.catmullRom)

                            AreaMark(
                                x: .value("Day", point.date),
                                y: .value("RPE", point.value)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [rpeColor.opacity(0.22), rpeColor.opacity(0)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .interpolationMethod(.catmullRom)
                        }

                        RuleMark(y: .value("Hard", 7))
                            .foregroundStyle(RTColor.secondaryText.opacity(0.35))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    }
                    .chartYScale(domain: 0...10)
                    .chartXAxis(.hidden)
                    .chartYAxis {
                        AxisMarks(position: .leading, values: [3, 7, 10]) { value in
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
                    .accessibilityLabel("Workout RPE trend last seven days")
                }
            }
            .padding(16)
        }
        .accessibilityIdentifier(SurfaceID.workoutRPECard)
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

enum WorkoutRPEBaseline {
    /// Evening workout RPE history for spark / baseline (workout days only).
    @MainActor
    static func history(from store: MetadataStore, days: Int = 14) -> [(date: Date, rpe: Double)] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<days).compactMap { offset -> (Date, Double)? in
            guard let date = cal.date(byAdding: .day, value: -offset, to: today),
                  let meta = store.metadataFor(date: date, timeOfDay: .evening),
                  meta.workoutToday,
                  let rpe = meta.workoutRPE else { return nil }
            return (date, Double(rpe))
        }
    }
}
