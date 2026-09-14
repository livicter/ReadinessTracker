import SwiftUI
#if os(iOS)
import UIKit
#endif

/// Snapshot-safe WHOOP dual-arc Recovery (inner) / Strain (outer).
/// Suitable for watchOS glance and `ImageRenderer` PNG capture — no RTColor / SurfaceID / UIKit.
struct CompactStrainRecoveryWheel: View {
    let strainScore: Double  // 0–21
    let recoveryScore: Double // 0–100
    let size: CGFloat
    var day: String = "TODAY"
    var showsDayCaption: Bool = true
    var minimumOuterWidth: CGFloat = 8
    var minimumInnerWidth: CGFloat = 6

    /// Recovery fill — matches `RTColor.optimal` / WatchTheme.lightGreen.
    var recoveryColor: Color = Color(red: 52/255, green: 199/255, blue: 89/255)
    /// Strain fill — matches `RTColor.caution` / WatchTheme.orange.
    var strainColor: Color = Color(red: 255/255, green: 149/255, blue: 0/255)
    var trackColor: Color = Color.primary.opacity(0.15)
    var valueColor: Color = .primary
    var captionColor: Color = .secondary

    private var layout: StrainRecoveryDualArcGeometry.Layout {
        StrainRecoveryDualArcGeometry.layout(
            size: size,
            minimumOuterWidth: minimumOuterWidth,
            minimumInnerWidth: minimumInnerWidth
        )
    }

    var body: some View {
        let layout = self.layout
        ZStack {
            // Outer track (Strain)
            Circle()
                .stroke(trackColor, lineWidth: layout.outerWidth)

            // Inner track (Recovery)
            Circle()
                .stroke(trackColor, lineWidth: layout.innerWidth)
                .padding(layout.ringInset)

            // Strain fill (outer)
            Circle()
                .trim(from: 0, to: StrainRecoveryDualArcGeometry.strainFraction(strainScore))
                .stroke(strainColor, style: StrokeStyle(lineWidth: layout.outerWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))

            // Recovery fill (inner)
            Circle()
                .trim(from: 0, to: StrainRecoveryDualArcGeometry.recoveryFraction(recoveryScore))
                .stroke(recoveryColor, style: StrokeStyle(lineWidth: layout.innerWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .padding(layout.ringInset)

            VStack(spacing: 1) {
                if showsDayCaption {
                    Text(day)
                        .font(.system(size: layout.captionFontSize, weight: .semibold))
                        .foregroundStyle(captionColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                Text("\(Int(recoveryScore.rounded()))%")
                    .font(.system(size: layout.centerScoreFontSize, weight: .bold, design: .rounded))
                    .foregroundStyle(valueColor)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text("Recovery")
                    .font(.system(size: max(7, layout.captionFontSize), weight: .semibold))
                    .foregroundStyle(recoveryColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(width: max(24, layout.holeDiameter * 0.9))
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "Strain \(String(format: "%.1f", strainScore)) of 21, Recovery \(Int(recoveryScore.rounded())) percent"
        )
    }
}

#if os(iOS)
/// Watch strain page chrome for audit PNG (`verify-watch-strain.png`).
/// Mirrors watchOS glance sizing on a black canvas (ImageRenderer runs in iOS unit tests).
struct WatchStrainChrome: View {
    let strainScore: Double
    let recoveryScore: Double

    private let recoveryColor = Color(red: 52/255, green: 199/255, blue: 89/255)
    private let strainColor = Color(red: 255/255, green: 149/255, blue: 0/255)

    var body: some View {
        VStack(spacing: 10) {
            CompactStrainRecoveryWheel(
                strainScore: strainScore,
                recoveryScore: recoveryScore,
                size: 110,
                day: "TODAY",
                minimumOuterWidth: 8,
                minimumInnerWidth: 6,
                trackColor: Color.white.opacity(0.18),
                valueColor: .white,
                captionColor: Color.white.opacity(0.55)
            )

            HStack(spacing: 16) {
                chromeMetric(color: recoveryColor, title: "Recovery", value: "\(Int(recoveryScore.rounded()))", unit: "%")
                chromeMetric(color: strainColor, title: "Strain", value: String(format: "%.1f", strainScore), unit: "/21")
            }

            Text("Strain")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.55))
        }
        .padding(16)
        .frame(width: 184, height: 248)
        .background(Color.black)
    }

    private func chromeMetric(color: Color, title: String, value: String, unit: String) -> some View {
        HStack(spacing: 6) {
            Capsule()
                .fill(color)
                .frame(width: 3, height: 22)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.55))
                HStack(alignment: .firstTextBaseline, spacing: 1) {
                    Text(value)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(color)
                        .monospacedDigit()
                    Text(unit)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.45))
                }
            }
        }
    }
}
#endif
