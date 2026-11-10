# Honest #629 / #641 / #800: Density tail meter (WHOOP wells)

Chrome-only WHOOP wells on the existing density tail meter (`fitbit.air.density.tail` / `health.air.density.tail`).
The ratio track and 7-bin histogram already encode the reading / tail category and are left intact (not flattened to a uniform 8/14 wash).
Idle (no density > 0 in the 14d window) = ghost/hairline 8/28 secondaryText; active complete (ratio >= 2, Fat) = 14/28 optimal; active negative (ratio < 0.5, Left, and has density) = 14/28 strain; else/partial (Balanced / Lean) = 14/28 accent.
Verb capsule keeps its existing tone. Copy, accessibilityIdentifier, accessibilityLabel, tail-ratio math, and READY formula unchanged.
SurfaceID: `fitbit.air.density.tail` / `health.air.density.tail`
Proof: UITest → `.audit/verify-density-tail.png`
