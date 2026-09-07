import SwiftUI

/// WHOOP-like Strain vs Recovery balance: side-by-side metrics with day-over-day deltas,
/// plus the composite balance score. Tappable on Today via NavigationLink.
struct StrainRecoveryBalanceCard: View {
    let balance: StrainRecoveryBalance
    /// Recovery 0–100 (wheel / WHOOP scale). When nil, card shows balance-only (legacy).
    var recovery: Int? = nil
    /// Strain 0–21. When nil, card shows balance-only.
    var strain: Double? = nil
    /// Day-over-day recovery delta (today − yesterday).
    var recoveryDelta: Int? = nil
    /// Day-over-day strain delta (today − yesterday).
    var strainDelta: Double? = nil
    var showsChevron: Bool = false

    private var zone: ScoreZone { ScoreZone(score: balance.score) }
    private var showsPair: Bool { recovery != nil && strain != nil }

    var body: some View {
        NativeCard {
            VStack(spacing: 12) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "scale.3d")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(zone.color)

                        Text("Balance")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(RTColor.secondaryText)
                    }

                    Spacer()

                    Text(balance.status)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(zone.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(zone.color.opacity(0.12))
                        .clipShape(Capsule())

                    if showsChevron {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(RTColor.tertiaryText)
                    }
                }

                if showsPair, let recovery, let strain {
                    HStack(spacing: 12) {
                        metricColumn(
                            label: "Recovery",
                            value: "\(recovery)",
                            unit: "%",
                            color: RTColor.optimal,
                            delta: recoveryDelta.map { Self.formatDelta(Int($0)) }
                        )

                        Rectangle()
                            .fill(RTColor.divider)
                            .frame(width: 1)
                            .padding(.vertical, 4)

                        metricColumn(
                            label: "Strain",
                            value: String(format: "%.1f", strain),
                            unit: "/21",
                            color: RTColor.caution,
                            delta: strainDelta.map { Self.formatDelta($0, decimals: 1) }
                        )
                    }
                    .accessibilityElement(children: .contain)
                }

                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("\(balance.score)")
                        .font(showsPair ? .title2.weight(.bold) : AppleTheme.heroValue)
                        .foregroundStyle(RTColor.primaryText)
                        .monospacedDigit()

                    Text(showsPair ? "balance" : "/ 100")
                        .font(.callout.weight(.medium))
                        .foregroundStyle(RTColor.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: showsPair ? .leading : .center)

                AnimatedProgressBar(
                    progress: Double(balance.score) / 100.0,
                    color: zone.color,
                    height: 8
                )

                if !showsPair {
                    HStack {
                        Text("Rest")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(RTColor.tertiaryText)

                        Spacer()

                        Text("Balanced")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(RTColor.tertiaryText)
                    }
                }

                Text("How recovery keeps up with your training load")
                    .font(.caption2)
                    .foregroundStyle(RTColor.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func metricColumn(
        label: String,
        value: String,
        unit: String,
        color: Color,
        delta: String?
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(RTColor.secondaryText)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
                    .monospacedDigit()
                Text(unit)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(RTColor.tertiaryText)
            }

            if let delta {
                Text(delta)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(deltaColor(delta))
                    .monospacedDigit()
            } else {
                Text("vs yesterday")
                    .font(.caption2)
                    .foregroundStyle(RTColor.tertiaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label) \(value)\(unit)")
    }

    private func deltaColor(_ text: String) -> Color {
        if text.hasPrefix("↑") { return RTColor.optimal }
        if text.hasPrefix("↓") { return RTColor.caution }
        return RTColor.tertiaryText
    }

    static func formatDelta(_ value: Int) -> String {
        if value > 0 { return "↑ +\(value)" }
        if value < 0 { return "↓ \(value)" }
        return "→ 0"
    }

    static func formatDelta(_ value: Double, decimals: Int) -> String {
        let fmt = "%.\(decimals)f"
        if value > 0.05 { return "↑ +\(String(format: fmt, value))" }
        if value < -0.05 { return "↓ \(String(format: fmt, value))" }
        return "→ 0"
    }
}
