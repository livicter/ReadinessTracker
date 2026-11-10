# Honest #578 / #656 / #805: Density percentile meter (WHOOP wells)

Chrome-only WHOOP wells on the existing density percentile meter (`fitbit.air.density.percentile` / `health.air.density.percentile`).
The P0–P100 gradient track and tonight marker already encode the percentile reading itself (strain→good→optimal gradient plus a tone-filled marker at x = pct * w) and are left intact (not flattened to a uniform 8/14 wash).
Idle (no density > 0 in the 14d window) = ghost/hairline 8/28 secondaryText; active complete (has density, High, pctPP >= 70) = 14/28 optimal; active negative (Low, pctPP < 40) = 14/28 strain; else/partial (Mid, 40 <= pctPP < 70) = 14/28 accent.
Verb capsule keeps its existing tone. Copy, accessibilityIdentifier, accessibilityLabel, percentile math, and READY formula unchanged.
SurfaceID: `fitbit.air.density.percentile` / `health.air.density.percentile`
Proof: UITest → `.audit/verify-density-percentile.png`
