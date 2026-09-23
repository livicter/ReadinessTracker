import SwiftUI
import Charts

/// Elevates morning check-in `hadNap` / `napQuality` (1–5) into a Tonight |
/// Baseline dual near Cognitive Load. Check-in nap was unused on Today.
/// CheckInStatusCard wells stay chrome-only — not a sleep-stack WHOOP dual.
struct NapTonightBaselineCard: View {
    let tonight: UserMetadata?
    let history: [(date: Date, quality: Double, minutes: Int)]

    private var tonightQuality: Double? {
        guard let meta = tonight, meta.hadNap, let q = meta.napQuality else { return nil }
        return Double(q)
    }

    private var tonightMinutes: Int? {
        guard let meta = tonight, meta.hadNap else { return nil }
        return meta.napDurationMinutes
    }

    private var base: Double {
        let values = history.map(\.quality).filter { $0 > 0 }
        if values.isEmpty { return tonightQuality ?? 0 }
        return values.reduce(0, +) / Double(values.count)
    }

    private var baseMinutes: Double {
        let values = history.map { Double($0.minutes) }.filter { $0 > 0 }
        guard !values.isEmpty else { return Double(tonightMinutes ?? 0) }
        return values.reduce(0, +) / Double(values.count)
    }

    private var delta: Double {
        guard let q = tonightQuality else { return 0 }
        return q - base
    }

    private var status: (label: String, color: Color) {
        guard let q = tonightQuality else {
            if tonight?.hadNap == false {
                return ("No nap", RTColor.secondaryText)
            }
            return ("No check-in", RTColor.secondaryText)
        }
        if q >= 4 { return ("Restorative", RTColor.optimal) }
        if q >= 3 { return ("Helpful", RTColor.good) }
        if q >= 2 { return ("Fair", RTColor.caution) }
        return ("Poor", RTColor.warning)
    }

    private var sparklineValues: [Double] {
        Array(history.sorted { $0.date < $1.date }.suffix(7).map(\.quality))
    }

    private var chartPoints: [(date: Date, value: Double)] {
        history.sorted { $0.date < $1.date }.map { (date: $0.date, value: $0.quality) }
    }

    private var deltaCaption: String {
        guard tonightQuality != nil else { return "Log morning check-in" }
        let sign = delta >= 0 ? "+" : ""
        return String(format: "%@%.1f vs baseline", sign, delta)
    }

    private var durationCaption: String {
        guard let mins = tonightMinutes else {
            return tonight?.hadNap == false ? "Skipped nap" : "No nap logged"
        }
        return "\(mins) min"
    }

    private var baselineCaption: String {
        guard base > 0 else { return "No nap history" }
        if baseMinutes > 0 {
            return String(format: "%.0f min avg · 7-day", baseMinutes)
        }
        return "7-day quality avg"
    }

    private let napColor = Color(hex: "64D2FF")

    var body: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Nap")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(RTColor.primaryText)

                        Text("Quality · \(status.label)")
                            .font(.subheadline)
                            .foregroundStyle(status.color)
                    }

                    Spacer()

                    Text(tonightQuality.map { String(format: "%.0f/5", $0) } ?? "—")
                        .font(.title2.weight(.bold).monospacedDigit())
                        .foregroundStyle(status.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(status.color.opacity(0.12))
                        .clipShape(Capsule())
                        .accessibilityLabel(
                            tonightQuality.map { "Nap quality \($0) of 5, \(status.label)" } ?? status.label
                        )
                }

                HStack(spacing: 12) {
                    dualColumn(
                        label: "Tonight",
                        valueText: tonightQuality.map { String(format: "%.0f", $0) } ?? "—",
                        unit: "/5",
                        color: status.color,
                        caption: durationCaption,
                        icon: "moon.zzz.fill"
                    )

                    Rectangle()
                        .fill(RTColor.divider)
                        .frame(width: 1)
                        .padding(.vertical, 4)

                    dualColumn(
                        label: "Baseline",
                        valueText: base > 0 ? String(format: "%.1f", base) : "—",
                        unit: "/5",
                        color: RTColor.secondaryText,
                        caption: baselineCaption,
                        icon: "chart.line.uptrend.xyaxis"
                    )
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier(SurfaceID.napBaselineCallout)

                if sparklineValues.count >= 2 {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("7-Day Nap Quality")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(RTColor.secondaryText)
                            Spacer()
                            Text(deltaCaption)
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(delta <= -1 ? RTColor.caution : RTColor.optimal)
                                .monospacedDigit()
                        }
                        AnimatedSparkline(data: sparklineValues, color: napColor)
                            .frame(height: 28)
                            .accessibilityIdentifier(SurfaceID.napSpark)
                    }
                }

                if chartPoints.count >= 3 {
                    Chart {
                        ForEach(Array(chartPoints.enumerated()), id: \.offset) { _, point in
                            LineMark(
                                x: .value("Day", point.date),
                                y: .value("Quality", point.value)
                            )
                            .foregroundStyle(napColor)
                            .interpolationMethod(.catmullRom)

                            AreaMark(
                                x: .value("Day", point.date),
                                y: .value("Quality", point.value)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [napColor.opacity(0.22), napColor.opacity(0)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .interpolationMethod(.catmullRom)
                        }

                        RuleMark(y: .value("Good", 3))
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
                    .accessibilityLabel("Nap quality trend last seven days")
                }
            }
            .padding(16)
        }
        .accessibilityIdentifier(SurfaceID.napCard)
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

enum NapBaseline {
    /// Morning nap-day history for spark / baseline (napped days only).
    @MainActor
    static func history(from store: MetadataStore, days: Int = 14) -> [(date: Date, quality: Double, minutes: Int)] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<days).compactMap { offset -> (Date, Double, Int)? in
            guard let date = cal.date(byAdding: .day, value: -offset, to: today),
                  let meta = store.metadataFor(date: date, timeOfDay: .morning),
                  meta.hadNap,
                  let q = meta.napQuality else { return nil }
            return (date, Double(q), meta.napDurationMinutes ?? 0)
        }
    }
}
