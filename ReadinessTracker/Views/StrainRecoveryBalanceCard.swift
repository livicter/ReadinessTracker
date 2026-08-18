import SwiftUI

struct StrainRecoveryBalanceCard: View {
    let balance: StrainRecoveryBalance

    private var zone: ScoreZone { ScoreZone(score: balance.score) }

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
                }

                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("\(balance.score)")
                        .font(AppleTheme.heroValue)
                        .foregroundStyle(.white)

                    Text("/ 100")
                        .font(.callout.weight(.medium))
                        .foregroundStyle(RTColor.secondaryText)
                }

                AnimatedProgressBar(
                    progress: Double(balance.score) / 100.0,
                    color: zone.color,
                    height: 8
                )
            }
        }
    }
}
