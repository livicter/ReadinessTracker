# Honest #586 / #665 / #809: Density slope meter (WHOOP wells)

Chrome-only WHOOP wells on the existing density slope meter (`fitbit.air.density.slope` / `health.air.density.slope`).
The dens spark PATH and dashed trend line already encode the signed slope and are left intact (not flattened to a uniform 8/14 wash).
Idle (no density > 0 in the 14d window) = ghost/hairline 8/28 secondaryText; active complete (has density, Stable, absPP < 0.4) = 14/28 optimal; active negative (Falling, absPP >= 0.4 && slopePP <= 0) = 14/28 strain; else/partial (Rising, absPP >= 0.4 && slopePP > 0) = 14/28 accent.
The verb capsule and pp/d footer keep their existing tones. Copy, accessibilityIdentifier, accessibilityLabel, slope math, and READY formula unchanged.
SurfaceID: `fitbit.air.density.slope` / `health.air.density.slope`
Proof: UITest → `.audit/verify-density-slope.png`
