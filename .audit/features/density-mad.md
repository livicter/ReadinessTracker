# Honest #582 / #667 / #807: Density MAD meter (WHOOP wells)

Chrome-only WHOOP wells on the existing density MAD meter (`fitbit.air.density.mad` / `health.air.density.mad`).
The ratio track already encodes the MAD reading itself (optimal/good/warning gradient capsule and tone-filled needle) and is left intact (not flattened to a uniform 8/14 wash).
Idle (no density > 0 in the 14d window) = ghost/hairline 8/28 secondaryText; active complete (has density, Stable, madPP <= 8) = 14/28 optimal; active negative (Volatile, madPP > 15) = 14/28 strain; else/partial (Mild, 8 < madPP <= 15) = 14/28 accent.
The verb capsule keeps its existing tone. Copy, accessibilityIdentifier, accessibilityLabel, MAD math, and READY formula unchanged.
SurfaceID: `fitbit.air.density.mad` / `health.air.density.mad`
Proof: UITest → `.audit/verify-density-mad.png`
