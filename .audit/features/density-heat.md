# Honest #525 / #684 / #794: Density heatmap (WHOOP cell chrome)

Chrome-only WHOOP cell hairlines on the existing density heatmap (`fitbit.air.density.heat` / `health.air.density.heat`).
Idle (dens == 0) = ghost/hairline 8/28 using secondaryText; active complete (dens == 1) = 28% optimal hairline; else/partial = 28% accent hairline. No negative state (density is non-negative).
Heat intensity fill (0.25 / 0.55 / 0.9) is preserved and is not replaced by a uniform 8/14 wash.
Copy, accessibilityIdentifier, accessibilityLabel, tap-to-select / spark-scrub math, and READY formula unchanged.
SurfaceID: `fitbit.air.density.heat` / `health.air.density.heat`
Proof: UITest → `.audit/verify-density-heat.png`
