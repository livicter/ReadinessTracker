# Honest #574 / #659 / #803: Density skew meter (WHOOP wells)

Chrome-only WHOOP wells on the existing density skew meter (`fitbit.air.density.skew` / `health.air.density.skew`).
The signed track already encodes the skew reading itself (left→right strain/accent/optimal gradient, center tick, and tone-filled needle) and is left intact (not flattened to a uniform 8/14 wash).
Idle (no density > 0 in the 14d window) = ghost/hairline 8/28 secondaryText; active complete (has density, near-symmetric, absS <= 0.5) = 14/28 optimal; active negative (strong left/right skew, absS > 1.0) = 14/28 strain; else/partial (moderate skew, 0.5 < absS <= 1.0) = 14/28 accent.
Verb capsule keeps its existing tone. Copy, accessibilityIdentifier, accessibilityLabel, skew math, and READY formula unchanged.
SurfaceID: `fitbit.air.density.skew` / `health.air.density.skew`
Proof: UITest → `.audit/verify-density-skew.png`
