# Honest #527 / #687 / #798: Density week-over-week badge (WHOOP wells)

Fitbit/Health week-over-week density badge under the 7-day density heatmap (above forecast + streak, when present).
Chrome-only WHOOP wells on the existing Honest #527 / #687 WoW badge button.
Idle (abs(deltaPP) < 0.5) = ghost/hairline 8/28 secondaryText; active complete (deltaPP > 0, up) = 14/28 optimal; active negative (deltaPP < 0, down) = 14/28 strain.
Inner pp capsule keeps its existing tone (warning for down, optimal for up). Detail wowStat row unchanged.
Copy, accessibilityIdentifier, accessibilityLabel, expand-toggle math, and READY formula unchanged. No new SID.
SurfaceID: `fitbit.air.density.wow` / `health.air.density.wow`
Proof: `.audit/verify-density-wow.png`
