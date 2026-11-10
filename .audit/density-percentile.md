# Honest #578 / #656 / #805: Density percentile meter (WHOOP wells)

Fitbit/Health air density mid-rank percentile meter immediately after the IQR meter on the Air card (below heatmap + WoW + forecast + streak + spark + hist + CV + skew + IQR; next unstyled meter body in the hist → gain/pain stack is the envelope chart).
Chrome-only WHOOP wells on the existing Honest #578 / #656 percentile meter container.
The P0–P100 gradient track and tonight marker already encode the percentile reading itself (strain→good→optimal gradient plus a tone-filled marker at x = pct * w). That track is left intact — not flattened to a uniform 8/14 wash.
Idle (no density > 0 in the 14d window) = ghost/hairline 8/28 secondaryText; active complete (has density, High, pctPP >= 70) = 14/28 optimal; active negative (Low, pctPP < 40) = 14/28 strain; else/partial (Mid, 40 <= pctPP < 70) = 14/28 accent.
The verb capsule keeps its existing tone (High / pctPP >= 70 / optimal, Mid / 40 <= pctPP < 70 / good, Low / pctPP < 40 / warning). Label contrast holds (no white text on a light wash).
Copy, accessibilityIdentifier, accessibilityLabel, percentile math, and READY formula unchanged. No new SID.
SurfaceID: `fitbit.air.density.percentile` / `health.air.density.percentile`
Proof: `.audit/verify-density-percentile.png`
