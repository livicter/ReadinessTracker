import CoreGraphics

/// Shared WHOOP-style dual-arc layout (Today `StrainRecoveryWheel` + Watch strain page).
/// Outer arc = Strain 0–21; inner arc = Recovery 0–100%. Independent fills from −90°.
/// Pure CoreGraphics — safe on watchOS without UIKit.
struct StrainRecoveryDualArcGeometry: Equatable {
    struct Layout: Equatable {
        let size: CGFloat
        let outerWidth: CGFloat
        let innerWidth: CGFloat
        /// Inset so the recovery track sits inside the strain track (WHOOP dual-arc gap).
        let ringInset: CGFloat
        let holeDiameter: CGFloat
        let centerScoreFontSize: CGFloat
        let captionFontSize: CGFloat
    }

    /// - Parameters:
    ///   - size: Outer diameter of the dual-arc canvas.
    ///   - minimumOuterWidth: Floor for the Strain stroke (Today uses 20; Watch glance ~8).
    ///   - minimumInnerWidth: Floor for the Recovery stroke (Today uses 14; Watch glance ~6).
    static func layout(
        size: CGFloat,
        minimumOuterWidth: CGFloat = 20,
        minimumInnerWidth: CGFloat = 14
    ) -> Layout {
        // Scale from the Today reference (180pt → outer 20 / inner 14 / inset 20).
        let scale = size / 180
        // At Today reference (180): outer 20 / inner 14 / inset 20 (inset == outer stroke).
        let outerWidth = max(minimumOuterWidth, 20 * scale)
        let innerWidth = max(minimumInnerWidth, 14 * scale)
        let ringInset = max(minimumOuterWidth, 20 * scale)
        let hole = max(0, size - 2 * ringInset - innerWidth)
        let scoreFontFloor: CGFloat = hole < 28 ? max(10, hole * 0.42) : 16
        let scoreFont = min(28, max(scoreFontFloor, hole * 0.34))
        let captionFont = max(7, scoreFont * 0.32)
        return Layout(
            size: size,
            outerWidth: outerWidth,
            innerWidth: innerWidth,
            ringInset: ringInset,
            holeDiameter: hole,
            centerScoreFontSize: scoreFont,
            captionFontSize: captionFont
        )
    }

    /// Strain progress for stroke trim (0…1 from 0–21 scale).
    static func strainFraction(_ strain: Double) -> CGFloat {
        CGFloat(min(max(strain / 21.0, 0), 1))
    }

    /// Recovery progress for stroke trim (0…1 from 0–100%).
    static func recoveryFraction(_ recovery: Double) -> CGFloat {
        CGFloat(min(max(recovery / 100.0, 0), 1))
    }
}
