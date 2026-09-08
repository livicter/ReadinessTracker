import SwiftUI

/// WHOOP-style dual-arc Recovery / Strain wheel.
/// Outer arc = Strain 0–21; inner arc = Recovery 0–100%. Independent fills from −90°.
struct StrainRecoveryWheel: View {
    let strainScore: Double  // 0-21 scale like Whoop
    let recoveryScore: Double // 0-100%
    let day: String // "TODAY" / "DAY 1"

    private var strainFraction: CGFloat {
        CGFloat(min(max(strainScore / 21.0, 0), 1))
    }

    private var recoveryFraction: CGFloat {
        CGFloat(min(max(recoveryScore / 100.0, 0), 1))
    }

    private let outerWidth: CGFloat = 20
    private let innerWidth: CGFloat = 14
    /// Inset so the recovery track sits inside the strain track (WHOOP dual-arc gap).
    private let ringInset: CGFloat = 20

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                // Outer track (Strain)
                Circle()
                    .stroke(RTColor.surfaceHighlight, lineWidth: outerWidth)

                // Inner track (Recovery)
                Circle()
                    .stroke(RTColor.surfaceHighlight, lineWidth: innerWidth)
                    .padding(ringInset)

                // Strain fill (outer)
                Circle()
                    .trim(from: 0, to: strainFraction)
                    .stroke(RTColor.caution, style: StrokeStyle(lineWidth: outerWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                // Recovery fill (inner)
                Circle()
                    .trim(from: 0, to: recoveryFraction)
                    .stroke(RTColor.optimal, style: StrokeStyle(lineWidth: innerWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .padding(ringInset)

                // Center metrics
                VStack(spacing: 2) {
                    Text(day)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(RTColor.secondaryText)

                    Text("\(Int(recoveryScore.rounded()))%")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(RTColor.primaryText)
                        .monospacedDigit()

                    Text("Recovery")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(RTColor.optimal)
                }
            }
            .frame(width: 180, height: 180)
            .accessibilityIdentifier(SurfaceID.strainRecoveryWheel)

            // Value legend (labels + numbers, not color dots alone)
            HStack(spacing: 28) {
                SRMetricLabel(
                    color: RTColor.optimal,
                    title: "Recovery",
                    value: "\(Int(recoveryScore.rounded()))",
                    unit: "%",
                    accessibilityId: SurfaceID.strainRecoveryWheelRecovery
                )
                SRMetricLabel(
                    color: RTColor.caution,
                    title: "Strain",
                    value: String(format: "%.1f", strainScore),
                    unit: "/21",
                    accessibilityId: SurfaceID.strainRecoveryWheelStrain
                )
            }
            .accessibilityIdentifier(SurfaceID.strainRecoveryWheelLegend)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(
            "Strain \(String(format: "%.1f", strainScore)) of 21, Recovery \(Int(recoveryScore.rounded())) percent"
        )
    }
}

private struct SRMetricLabel: View {
    let color: Color
    let title: String
    let value: String
    let unit: String
    let accessibilityId: String

    var body: some View {
        HStack(spacing: 8) {
            Capsule()
                .fill(color)
                .frame(width: 4, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(color)
                        .monospacedDigit()
                    Text(unit)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(RTColor.tertiaryText)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(accessibilityId)
        .accessibilityLabel("\(title) \(value)\(unit)")
    }
}
