import SwiftUI
import Charts

/// Elevates the WHOOP-style 0–21 **strain** score that iOS already pushes into
/// the Watch complication snapshot (`WatchConnectivityManager.Key.strain`) but
/// that Watch faces still ignore (rings-only / sample fallback). Tonight |
/// Baseline on Today Recovery & Strain — same number the Watch App Group carries.
/// Complements Daily TRIMP (session points) without re-chroming the balance wheel.
struct WatchStrainTonightBaselineCard: View {
    let tonightStrain: Double
    let history: [(date: Date, strain: Double)]
    let baseline: Double

    private var tonight: Double { max(0, min(21, tonightStrain)) }

    private var base: Double {
        let b = baseline > 0 ? baseline : tonight
        return max(0, min(21, b))
    }

    private var delta: Double { tonight - base }

    private var status: (label: String, color: Color) {
        // WHOOP-ish bands on the 0–21 scale.
        if tonight >= 14 { return ("All out", RTColor.warning) }
        if tonight >= 10 { return ("Hard", RTColor.caution) }
        if tonight >= 6 { return ("Moderate", RTColor.good) }
        if tonight >= 3 { return ("Light", RTColor.optimal) }
        return ("Rest", RTColor.secondaryText)
    }

    private var sparklineValues: [Double] {
        Array(history.sorted { $0.date < $1.date }.suffix(7).map(\.strain))
    }

    private var chartPoints: [(date: Date, value: Double)] {
        history.sorted { $0.date < $1.date }.map { (date: $0.date, value: $0.strain) }
    }

    private var deltaCaption: String {
        let sign = delta >= 0 ? "+" : ""
        return String(format: "%@%.1f vs baseline", sign, delta)
    }

    private let strainColor = Color(hex: "FF9F0A")

    var body: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Watch Strain")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(RTColor.primaryText)

                        Text("Face snapshot · \(status.label)")
                            .font(.subheadline)
                            .foregroundStyle(status.color)
                    }

                    Spacer()

                    Text(String(format: "%.1f", tonight))
                        .font(.title2.weight(.bold).monospacedDigit())
                        .foregroundStyle(status.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(status.color.opacity(0.12))
                        .clipShape(Capsule())
                        .accessibilityLabel(
                            String(format: "Watch strain %.1f of 21, %@", tonight, status.label)
                        )
                }

                HStack(spacing: 12) {
                    dualColumn(
                        label: "Tonight",
                        valueText: String(format: "%.1f", tonight),
                        unit: "/21",
                        color: status.color,
                        caption: "Pushed to Watch",
                        icon: "applewatch"
                    )

                    Rectangle()
                        .fill(RTColor.divider)
                        .frame(width: 1)
                        .padding(.vertical, 4)

                    dualColumn(
                        label: "Baseline",
                        valueText: String(format: "%.1f", base),
                        unit: "/21",
                        color: RTColor.secondaryText,
                        caption: "7-day strain avg",
                        icon: "chart.line.uptrend.xyaxis"
                    )
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier(SurfaceID.watchStrainBaselineCallout)

                if sparklineValues.count >= 2 {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("7-Day Watch Strain")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(RTColor.secondaryText)
                            Spacer()
                            Text(deltaCaption)
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(delta >= 2.5 ? RTColor.caution : RTColor.optimal)
                                .monospacedDigit()
                        }
                        AnimatedSparkline(data: sparklineValues, color: strainColor)
                            .frame(height: 28)
                            .accessibilityIdentifier(SurfaceID.watchStrainSpark)
                    }
                }

                if chartPoints.count >= 3 {
                    Chart {
                        ForEach(Array(chartPoints.enumerated()), id: \.offset) { _, point in
                            LineMark(
                                x: .value("Day", point.date),
                                y: .value("Strain", point.value)
                            )
                            .foregroundStyle(strainColor)
                            .interpolationMethod(.catmullRom)

                            AreaMark(
                                x: .value("Day", point.date),
                                y: .value("Strain", point.value)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [strainColor.opacity(0.22), strainColor.opacity(0)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .interpolationMethod(.catmullRom)
                        }

                        RuleMark(y: .value("Hard", 10))
                            .foregroundStyle(RTColor.secondaryText.opacity(0.35))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    }
                    .chartYScale(domain: 0...21)
                    .chartXAxis(.hidden)
                    .chartYAxis {
                        AxisMarks(position: .leading, values: [0, 10, 21]) { value in
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
                    .accessibilityLabel("Watch strain trend last seven days")
                }
            }
            .padding(16)
        }
        .accessibilityIdentifier(SurfaceID.watchStrainCard)
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

enum WatchStrainBaseline {
    static func average(
        from history: [DailyHealthData],
        window: Int = 7,
        fallback: Double
    ) -> Double {
        let recent = history
            .sorted { $0.date > $1.date }
            .prefix(window)
        let values = recent.map { StrainCalculator.calculate(from: $0, history: history) }
        guard !values.isEmpty else { return fallback }
        return values.reduce(0, +) / Double(values.count)
    }
}
