import SwiftUI

/// WHOOP-style sleep debt: clear debt-hours graphic, payback cue,
/// and a 7-night spark + daily change bars (bank-account glance).
struct SleepDebtCalculator: View {
    let history: [(date: Date, sleepHours: Double)]
    let sleepNeed: Double // Personal sleep need in hours (e.g. 8.0)

    private var debtData: [(date: Date, cumulativeDebt: Double, dailyHours: Double, dailyChange: Double)] {
        var cumulative: Double = 0
        var result: [(date: Date, cumulativeDebt: Double, dailyHours: Double, dailyChange: Double)] = []

        for item in history.sorted(by: { $0.date < $1.date }) {
            let dailyChange = item.sleepHours - sleepNeed
            cumulative += dailyChange
            result.append((item.date, cumulative, item.sleepHours, dailyChange))
        }

        return result
    }

    private var currentDebt: Double {
        debtData.last?.cumulativeDebt ?? 0
    }

    /// Hours owed (positive when behind need). Surplus is negative debt in bank terms,
    /// but UI treats `hoursOwed` as max(0, -currentDebt).
    private var hoursOwed: Double { max(0, -currentDebt) }
    private var hoursBanked: Double { max(0, currentDebt) }

    private var lastNightChange: Double {
        debtData.last?.dailyChange ?? 0
    }

    private var debtStatus: (label: String, color: Color) {
        if currentDebt > 2 { return ("Well Rested", RTColor.optimal) }
        if currentDebt > -2 { return ("Balanced", RTColor.good) }
        if currentDebt > -5 { return ("Mild Debt", RTColor.caution) }
        return ("Sleep Debt", RTColor.warning)
    }

    /// Last 7 nights cumulative balance for spark (oldest → newest).
    private var sparklineValues: [Double] {
        Array(debtData.suffix(7).map(\.cumulativeDebt))
    }

    private var last7: [(date: Date, cumulativeDebt: Double, dailyHours: Double, dailyChange: Double)] {
        Array(debtData.suffix(7))
    }

    /// Payback at +1.0h surplus per night (WHOOP-like recovery cue).
    private var paybackNights: Int {
        guard hoursOwed > 0.05 else { return 0 }
        return max(1, Int(ceil(hoursOwed / 1.0)))
    }

    private var paybackCue: String {
        if hoursOwed > 0.05 {
            let nights = paybackNights
            let nightWord = nights == 1 ? "night" : "nights"
            return "Pay back ≈\(String(format: "%.1f", hoursOwed))h over \(nights) \(nightWord) (+1.0h each). Earlier bedtime helps."
        }
        if hoursBanked > 0.05 {
            return "Banked +\(String(format: "%.1f", hoursBanked))h vs need. Keep the streak going."
        }
        return "On target vs \(String(format: "%.1f", sleepNeed))h need. Maintain your schedule."
    }

    /// Gauge fill magnitude capped for readable bar (hours).
    private var gaugeCap: Double {
        max(abs(currentDebt), 4.0, sleepNeed * 0.5)
    }

    var body: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 14) {
                // Header
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sleep Debt")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(RTColor.primaryText)

                        Text("Cumulative vs \(String(format: "%.1f", sleepNeed))h need")
                            .font(.subheadline)
                            .foregroundStyle(RTColor.secondaryText)
                    }

                    Spacer()

                    let status = debtStatus
                    Text(status.label)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(status.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(status.color.opacity(0.12))
                        .clipShape(Capsule())
                        .accessibilityLabel(status.label)
                }

                // Clear debt-hours graphic: Debt | Last night dual + zero-centered gauge
                HStack(spacing: 12) {
                    debtColumn(
                        label: currentDebt >= 0 ? "Banked" : "Debt",
                        hours: abs(currentDebt),
                        color: debtStatus.color,
                        caption: currentDebt >= 0 ? "surplus vs need" : "hours owed"
                    )

                    Rectangle()
                        .fill(RTColor.divider)
                        .frame(width: 1)
                        .padding(.vertical, 4)

                    debtColumn(
                        label: "Last night",
                        hours: abs(lastNightChange),
                        color: lastNightChange >= 0 ? RTColor.optimal : RTColor.warning,
                        caption: lastNightDeltaCaption,
                        signed: true,
                        signedValue: lastNightChange
                    )
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier(SurfaceID.sleepDebtHours)

                // Zero-centered debt hours bar
                VStack(alignment: .leading, spacing: 6) {
                    GeometryReader { geo in
                        let w = geo.size.width
                        let mid = w / 2
                        let fill = mid * CGFloat(min(1, abs(currentDebt) / gaugeCap))

                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(RTColor.surfaceHighlight)
                                .frame(height: 14)

                            // Zero tick
                            Capsule()
                                .fill(RTColor.primaryText.opacity(0.45))
                                .frame(width: 2, height: 18)
                                .position(x: mid, y: 7)

                            if currentDebt >= 0 {
                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                    .fill(RTColor.optimal.opacity(0.85))
                                    .frame(width: max(4, fill), height: 14)
                                    .offset(x: mid)
                            } else {
                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                    .fill(debtStatus.color.opacity(0.85))
                                    .frame(width: max(4, fill), height: 14)
                                    .offset(x: mid - max(4, fill))
                            }
                        }
                    }
                    .frame(height: 18)
                    .accessibilityLabel(debtGaugeAccessibility)

                    HStack {
                        Text("Debt")
                            .font(.caption2)
                            .foregroundStyle(RTColor.tertiaryText)
                        Spacer()
                        Text("Surplus")
                            .font(.caption2)
                            .foregroundStyle(RTColor.tertiaryText)
                    }
                }

                // Payback cue
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: hoursOwed > 0.05 ? "moon.zzz.fill" : "checkmark.seal.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(hoursOwed > 0.05 ? debtStatus.color : RTColor.optimal)
                        .padding(.top, 1)
                    Text(paybackCue)
                        .font(.caption)
                        .foregroundStyle(RTColor.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: AppleTheme.cornerRadiusMedium, style: .continuous)
                        .fill(RTColor.surface)
                )
                .accessibilityIdentifier(SurfaceID.sleepDebtPayback)
                .accessibilityLabel(paybackCue)

                // Compact 7-night cumulative spark
                if sparklineValues.count >= 2 {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("7-Night Balance")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(RTColor.secondaryText)
                            Spacer()
                            let sign = currentDebt >= 0 ? "+" : ""
                            Text("\(sign)\(String(format: "%.1f", currentDebt))h")
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(debtStatus.color)
                                .monospacedDigit()
                        }
                        AnimatedSparkline(data: sparklineValues, color: debtStatus.color)
                            .frame(height: 28)
                            .accessibilityIdentifier(SurfaceID.sleepDebtSpark)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // 7-night daily change bars (stacked around zero glance)
                if last7.count >= 2 {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Daily vs need")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(RTColor.secondaryText)

                        HStack(alignment: .bottom, spacing: 8) {
                            ForEach(last7.indices, id: \.self) { i in
                                let item = last7[i]
                                let change = item.dailyChange
                                let dayLabel = Calendar.current.shortWeekdaySymbols[
                                    Calendar.current.component(.weekday, from: item.date) - 1
                                ]

                                VStack(spacing: 4) {
                                    Text(String(dayLabel.prefix(1)))
                                        .font(.caption2.weight(.medium))
                                        .foregroundStyle(RTColor.secondaryText)

                                    // Zero-centered mini stack
                                    ZStack(alignment: .center) {
                                        Rectangle()
                                            .fill(RTColor.divider.opacity(0.6))
                                            .frame(width: 22, height: 1)

                                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                                            .fill(change >= 0 ? RTColor.optimal : RTColor.warning)
                                            .frame(width: 14, height: max(3, min(28, abs(change) * 14)))
                                            .offset(y: change >= 0 ? -max(1.5, min(14, abs(change) * 7)) : max(1.5, min(14, abs(change) * 7)))
                                    }
                                    .frame(height: 36)

                                    Text(String(format: "%+.1f", change))
                                        .font(.system(size: 9, weight: .medium))
                                        .foregroundStyle(RTColor.primaryText)
                                        .monospacedDigit()
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.7)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .accessibilityIdentifier(SurfaceID.sleepDebtBars)
                    }
                    .padding(.top, 2)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(SurfaceID.sleepDebtCard)
        .accessibilityLabel("Sleep Debt")
    }

    private var lastNightDeltaCaption: String {
        let sign = lastNightChange >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", lastNightChange))h vs need"
    }

    private var debtGaugeAccessibility: String {
        if currentDebt >= 0 {
            return "Banked \(String(format: "%.1f", currentDebt)) hours versus need"
        }
        return "Sleep debt \(String(format: "%.1f", hoursOwed)) hours owed"
    }

    private func debtColumn(
        label: String,
        hours: Double,
        color: Color,
        caption: String,
        signed: Bool = false,
        signedValue: Double = 0
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(RTColor.secondaryText)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                if signed {
                    let sign = signedValue >= 0 ? "+" : "−"
                    Text("\(sign)\(String(format: "%.1f", abs(signedValue)))")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(color)
                        .monospacedDigit()
                } else {
                    Text(String(format: "%.1f", hours))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(color)
                        .monospacedDigit()
                }
                Text("h")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(RTColor.tertiaryText)
            }

            Text(caption)
                .font(.caption2)
                .foregroundStyle(RTColor.tertiaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label) \(String(format: "%.1f", signed ? signedValue : hours)) hours")
    }
}
