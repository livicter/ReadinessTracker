# Honest #582 / #667 / #807: Density MAD meter (WHOOP wells)

Fitbit/Health air density median-absolute-deviation meter of last-14 dens, immediately after the envelope chart on the Air card (below heatmap + WoW + forecast + streak + spark + hist + CV + skew + IQR + percentile + envelope; next unstyled meter body in the hist → gain/pain stack is the Tukey fences).
Chrome-only WHOOP wells on the existing Honest #582 / #667 MAD meter container.
The ratio track already encodes the MAD reading itself (optimal/good/warning gradient capsule and tone-filled needle). That track is left intact — not flattened to a uniform 8/14 wash.
Idle (no density > 0 in the 14d window) = ghost/hairline 8/28 secondaryText; active complete (has density, Stable, madPP <= 8) = 14/28 optimal; active negative (Volatile, madPP > 15) = 14/28 strain; else/partial (Mild, 8 < madPP <= 15) = 14/28 accent.
The verb capsule keeps its existing tone. Label contrast holds (no white text on a light wash).
Copy, accessibilityIdentifier, accessibilityLabel, MAD math, and READY formula unchanged. No new SID.
SurfaceID: `fitbit.air.density.mad` / `health.air.density.mad`
Proof: `.audit/verify-density-mad.png`
