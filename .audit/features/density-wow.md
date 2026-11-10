# Honest #527 / #687 / #798: Density week-over-week badge (WHOOP wells)

Chrome-only WHOOP wells on the existing density week-over-week badge (`fitbit.air.density.wow` / `health.air.density.wow`).
Idle (abs(deltaPP) < 0.5) = ghost/hairline 8/28 secondaryText; active complete (deltaPP > 0, up) = 14/28 optimal; active negative (deltaPP < 0, down) = 14/28 strain.
Inner pp capsule keeps its existing tone (warning for down, optimal for up). Detail wowStat row unchanged. Copy, accessibilityIdentifier, accessibilityLabel, expand-toggle math, and READY formula unchanged.
SurfaceID: `fitbit.air.density.wow` / `health.air.density.wow`
Proof: UITest → `.audit/verify-density-wow.png`
