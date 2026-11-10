# Honest #534 / #683 / #796: Density forecast badge (WHOOP wells)

Fitbit/Health tomorrow density forecast badge under the 7-day density heatmap (and WoW, when present).
Chrome-only WHOOP wells on the existing Honest #534 / #683 forecast badge button.
Idle (abs(deltaPP) < 0.5) = ghost/hairline 8/28 secondaryText; active complete (deltaPP > 0, up) = 14/28 optimal; active negative (deltaPP < 0, down) = 14/28 strain.
Inner delta / vs-mean capsules keep their existing tone (warning for down, optimal for up).
Copy, accessibilityIdentifier, accessibilityLabel, expand-toggle math, and READY formula unchanged. No new SID.
SurfaceID: `fitbit.air.density.forecast` / `health.air.density.forecast`
Proof: `.audit/verify-density-forecast.png`
