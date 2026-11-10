# Honest #584 / #666 / #808: Density Tukey fences (WHOOP wells)

Fitbit/Health air density Tukey fences of last-14 dens, immediately after the MAD meter on the Air card (below heatmap + WoW + forecast + streak + spark + hist + CV + skew + IQR + percentile + envelope + MAD; next unstyled meter body in the hist → gain/pain stack is the slope meter).
Chrome-only WHOOP wells on the existing Honest #584 / #666 Tukey fences container.
The box + 1.5×IQR whiskers, fence caps, IQR box gradient, median tick, and outlier dots already encode the fence geometry. Those marks are left intact — not flattened to a uniform 8/14 wash.
Idle (no density > 0 in the 14d window) = ghost/hairline 8/28 secondaryText; active complete (has density, Clean, outN == 0) = 14/28 optimal; active negative (outN > 2) = 14/28 strain; else/partial (1–2 outliers) = 14/28 accent.
The verb capsule keeps its existing tone. Label contrast holds (no white text on a light wash).
Copy, accessibilityIdentifier, accessibilityLabel, Tukey math, and READY formula unchanged. No new SID.
SurfaceID: `fitbit.air.density.tukey` / `health.air.density.tukey`
Proof: `.audit/verify-density-tukey.png`
