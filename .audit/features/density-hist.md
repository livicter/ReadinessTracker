# Honest #570 / #669 / #801: Density distribution hist (WHOOP wells)

Chrome-only WHOOP wells on the existing density distribution hist (`fitbit.air.density.hist` / `health.air.density.hist`).
The 4-bin Chart already encodes density-band identity by bar opacity (0.35 + 0.2 * bin.id) and is left intact (not flattened to a uniform 8/14 wash).
Idle (no density > 0 in the 14d window) = ghost/hairline 8/28 secondaryText; active complete (mean in the 75–100 band, meanPP >= 75) = 14/28 optimal; active negative (has density, mean in the 0–24 band, meanPP < 25) = 14/28 strain; else/partial (mean in 25–49 or 50–74) = 14/28 accent.
Mean capsule keeps its existing tone. Copy, accessibilityIdentifier, accessibilityLabel, hist bin math, and READY formula unchanged.
SurfaceID: `fitbit.air.density.hist` / `health.air.density.hist`
Proof: UITest → `.audit/verify-density-hist.png`
