# Honest #584 / #666 / #808: Density Tukey fences (WHOOP wells)

Chrome-only WHOOP wells on the existing density Tukey fences meter (`fitbit.air.density.tukey` / `health.air.density.tukey`).
The box + 1.5×IQR whiskers, fence caps, IQR box gradient, median tick, and outlier dots already encode the fence geometry and are left intact (not flattened to a uniform 8/14 wash).
Idle (no density > 0 in the 14d window) = ghost/hairline 8/28 secondaryText; active complete (has density, Clean, outN == 0) = 14/28 optimal; active negative (outN > 2) = 14/28 strain; else/partial (1–2 outliers) = 14/28 accent.
The verb capsule keeps its existing tone. Copy, accessibilityIdentifier, accessibilityLabel, Tukey math, and READY formula unchanged.
SurfaceID: `fitbit.air.density.tukey` / `health.air.density.tukey`
Proof: UITest → `.audit/verify-density-tukey.png`
