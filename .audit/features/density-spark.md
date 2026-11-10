# Honest #514 / #689 / #799: Density history spark (WHOOP wells)

Chrome-only WHOOP wells on the existing density history spark (`fitbit.air.density.spark` / `health.air.density.spark`).
The spark PATH already encodes history and is left intact (not flattened to a uniform 8/14 wash).
Idle (no density > 0 in the window) = ghost/hairline 8/28 secondaryText; else/partial (has history) = 14/28 accent.
No natural complete/negative state. Mean/range capsules keep existing tones. Copy, accessibilityIdentifier, accessibilityLabel, scrub/period math, and READY formula unchanged.
SurfaceID: `fitbit.air.density.spark` / `health.air.density.spark`
Proof: UITest → `.audit/verify-density-spark.png`
