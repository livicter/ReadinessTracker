import SwiftUI
import Charts

/// Elevates HealthKit blood pressure (systolic/diastolic mmHg) into Tonight | Baseline on
/// Today body after Blood Glucose. Net-new DailyHealthData + HK (#188).
/// Prefer BP — unused vitals; combined card (systolic drives spark/baseline).
struct BloodPressureTonightBaselineCard: View {
    let systolic: Double?
    let diastolic: Double?
    let history: [(date: Date, systolic: Double, diastolic: Double)]
    let baselineSystolic: Double

    private var tonightSys: Double? { systolic.map { max(0, $0) } }
    private var tonightDia: Double? { diastolic.map { max(0, $0) } }

    private var base: Double {
        let b = baselineSystolic > 0 ? baselineSystolic : (tonightSys ?? 0)
        return max(0, b)
    }

    private var delta: Double {
        guard let t = tonightSys else { return 0 }
        return t - base
    }

    private var status: (label: String, color: Color) {
        guard let s = tonightSys else {
            return ("No reading", RTColor.secondaryText)
        }
        // Soft AHA-style systolic glance bands (not a diagnosis).
        if s < 120 { return ("Optimal", RTColor.optimal) }
        if s < 130 { return ("Elevated", RTColor.caution) }
        if s < 140 { return ("High", RTColor.warning) }
        return ("Very high", RTColor.warning)
    }

    private var sparklineValues: [Double] {
        Array(history.sorted { $0.date < $1.date }.suffix(7).map(\.systolic))
    }

    private var chartPoints: [(date: Date, value: Double)] {
        history.sorted { $0.date < $1.date }.map { (date: $0.date, value: $0.systolic) }
    }

    private var readingText: String {
        guard let s = tonightSys else { return "—" }
        if let d = tonightDia {
            return "\(Int(s.rounded()))/\(Int(d.rounded()))"
        }
        return "\(Int(s.rounded()))"
    }

    private var deltaCaption: String {
        guard tonightSys != nil else { return "No BP logged" }
        let sign = delta >= 0 ? "+" : ""
        return "\(sign)\(Int(delta.rounded())) sys vs baseline"
    }

    private let bpColor = Color(hex: "FF2D55")

    var body: some View {
        Group {
            if tonightSys != nil || !history.isEmpty {
                cardBody
                    .accessibilityIdentifier(SurfaceID.bloodPressureCard)
            }
        }
    }

    private var cardBody: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Blood Pressure")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(RTColor.primaryText)

                        Text("Vitals · \(status.label)")
                            .font(.subheadline)
                            .foregroundStyle(status.color)
                    }

                    Spacer()

                    Text(readingText)
                        .font(.title2.weight(.bold).monospacedDigit())
                        .foregroundStyle(status.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(status.color.opacity(0.12))
                        .clipShape(Capsule())
                        .accessibilityLabel(
                            tonightSys.map { s in
                                if let d = tonightDia {
                                    return "Blood pressure \(Int(s.rounded())) over \(Int(d.rounded())), \(status.label)"
                                }
                                return "Blood pressure systolic \(Int(s.rounded())), \(status.label)"
                            } ?? "No BP logged"
                        )
                }

                HStack(spacing: 12) {
                    dualColumn(
                        label: "Tonight",
                        valueText: readingText,
                        unit: "mmHg",
                        color: status.color,
                        caption: "Sys / Dia",
                        icon: "heart.fill"
                    )

                    Rectangle()
                        .fill(RTColor.divider)
                        .frame(width: 1)
                        .padding(.vertical, 4)

                    dualColumn(
                        label: "Baseline",
                        valueText: base > 0 ? "\(Int(base.rounded()))" : "—",
                        unit: "sys",
                        color: RTColor.secondaryText,
                        caption: "7-day avg sys",
                        icon: "chart.line.uptrend.xyaxis"
                    )
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier(SurfaceID.bloodPressureBaselineCallout)

                if sparklineValues.count >= 2 {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("7-Day Systolic")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(RTColor.secondaryText)
                            Spacer()
                            Text(deltaCaption)
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(abs(delta) < 5 ? RTColor.optimal : RTColor.caution)
                                .monospacedDigit()
                        }
                        AnimatedSparkline(data: sparklineValues, color: bpColor)
                            .frame(height: 28)
                            .accessibilityIdentifier(SurfaceID.bloodPressureSpark)
                    }
                }

                if chartPoints.count >= 3 {
                    Chart {
                        ForEach(Array(chartPoints.enumerated()), id: \.offset) { _, point in
                            LineMark(
                                x: .value("Day", point.date),
                                y: .value("sys", point.value)
                            )
                            .foregroundStyle(bpColor)
                            .interpolationMethod(.catmullRom)

                            AreaMark(
                                x: .value("Day", point.date),
                                y: .value("sys", point.value)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [bpColor.opacity(0.2), bpColor.opacity(0)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .interpolationMethod(.catmullRom)
                        }

                        RuleMark(y: .value("Optimal", 120))
                            .foregroundStyle(RTColor.secondaryText.opacity(0.35))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    }
                    .chartYScale(domain: yDomain)
                    .chartXAxis(.hidden)
                    .chartYAxis {
                        AxisMarks(position: .leading, values: yMarks) { value in
                            AxisGridLine()
                            AxisValueLabel {
                                if let v = value.as(Double.self) {
                                    Text("\(Int(v.rounded()))")
                                        .font(.caption2)
                                        .foregroundStyle(RTColor.secondaryText)
                                }
                            }
                        }
                    }
                    .frame(height: 88)
                    .accessibilityLabel("Systolic blood pressure trend last seven days")
                }
            }
            .padding(16)
        }
        .accessibilityIdentifier(SurfaceID.bloodPressureCard)
    }

    private var yDomain: ClosedRange<Double> {
        let vals = chartPoints.map(\.value) + [base, tonightSys ?? base, 120].filter { $0 >= 0 }
        let lo = max(80.0, (vals.min() ?? 100) - 10)
        let hi = max(140.0, (vals.max() ?? 130) + 10)
        return lo...hi
    }

    private var yMarks: [Double] {
        let mid = ((yDomain.lowerBound + yDomain.upperBound) / 2).rounded()
        return [yDomain.lowerBound.rounded(), mid, yDomain.upperBound.rounded()]
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

enum BloodPressureBaseline {
    static func averageSystolic(
        from history: [DailyHealthData],
        window: Int = 7,
        fallback: Double
    ) -> Double {
        let values = history
            .sorted { $0.date > $1.date }
            .prefix(window)
            .compactMap(\.bloodPressureSystolicMmHg)
            .filter { $0 > 0 }
        guard !values.isEmpty else { return fallback }
        return values.reduce(0, +) / Double(values.count)
    }
}
