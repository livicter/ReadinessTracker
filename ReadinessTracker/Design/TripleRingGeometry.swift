import CoreGraphics

/// Shared Apple Fitness–style concentric ring layout (Today hero + Home Screen widget).
/// Diameters: outer `size`, middle `size - 2*(lineWidth+gap)`, inner `size - 4*(lineWidth+gap)`.
/// Center score is overlay-only and never drives radius (Honest gap #3 / #15 packing).
struct TripleRingGeometry: Equatable {
    struct Layout: Equatable {
        let size: CGFloat
        let lineWidth: CGFloat
        let gap: CGFloat
        let outerSize: CGFloat
        let middleSize: CGFloat
        let innerSize: CGFloat
        let holeDiameter: CGFloat
        let scoreFontSize: CGFloat
        let captionFontSize: CGFloat
    }

    /// - Parameters:
    ///   - size: Outer ring diameter.
    ///   - minimumLineWidth: Floor for stroke (hero uses 12; compact widget uses ~5).
    ///   - gap: Inter-ring gap (Today locks 2).
    static func layout(
        size: CGFloat,
        minimumLineWidth: CGFloat = 12,
        gap: CGFloat = 2
    ) -> Layout {
        let lineWidth = max(minimumLineWidth, size / 10)
        let step = lineWidth + gap
        let outer = size
        let middle = size - 2 * step
        let inner = size - 4 * step
        let hole = max(0, size - 4 * step - lineWidth)
        let scoreFont = min(34, max(14, hole * 0.30))
        let captionFont = max(7, scoreFont * 0.28)
        return Layout(
            size: size,
            lineWidth: lineWidth,
            gap: gap,
            outerSize: outer,
            middleSize: middle,
            innerSize: inner,
            holeDiameter: hole,
            scoreFontSize: scoreFont,
            captionFontSize: captionFont
        )
    }

    /// Overall readiness shown in the hole — mean of Gym / Work / Sleep (0...100).
    static func overallScore(gym: Int, work: Int, sleep: Int) -> Int {
        Int((Double(gym) + Double(work) + Double(sleep)) / 3.0)
    }

    /// Clamp progress for stroke trim.
    static func progress(score: Int) -> CGFloat {
        min(max(CGFloat(score) / 100, 0), 1)
    }
}
