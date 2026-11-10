# Honest #574 / #659 / #803: Density skew meter (WHOOP wells)

Fitbit/Health air density Pearson moment-skewness meter immediately after the CV meter on the Air card (below heatmap + WoW + forecast + streak + spark + hist + CV; next unstyled meter body in the hist → gain/pain stack).
Chrome-only WHOOP wells on the existing Honest #574 / #659 skew meter container.
The signed track already encodes the skew reading itself (left→right strain/accent/optimal gradient, center tick, and tone-filled needle at needle = clamp(skew/2, -1, 1)). That track is left intact — not flattened to a uniform 8/14 wash.
Idle (no density > 0 in the 14d window) = ghost/hairline 8/28 secondaryText; active complete (has density, near-symmetric, absS <= 0.5) = 14/28 optimal; active negative (strong left/right skew, absS > 1.0) = 14/28 strain; else/partial (moderate skew, 0.5 < absS <= 1.0) = 14/28 accent.
The verb capsule keeps its existing tone (Sym or absS <= 0.5 / optimal, 0.5 < absS <= 1.0 / good, absS > 1.0 / warning). Label contrast holds (no white text on a light wash).
Copy, accessibilityIdentifier, accessibilityLabel, skew math, and READY formula unchanged. No new SID.
SurfaceID: `fitbit.air.density.skew` / `health.air.density.skew`
Proof: `.audit/verify-density-skew.png`
