# Honest #570 / #669 / #801: Density distribution hist (WHOOP wells)

Fitbit/Health air density distribution histogram immediately after the history spark on the Air card (below heatmap + WoW + forecast + streak + spark; first unstyled meter body in the hist → gain/pain stack).
Chrome-only WHOOP wells on the existing Honest #570 / #669 hist container.
The 4-bin Chart already encodes density-band identity by bar opacity (0.35 + 0.2 * bin.id: 0–24 light → 75–100 near-solid of meterColor). Those fills are left intact — not flattened to a uniform 8/14 wash.
Idle (no density > 0 in the 14d window) = ghost/hairline 8/28 secondaryText; active complete (mean in the 75–100 band, meanPP >= 75) = 14/28 optimal; active negative (has density, mean in the 0–24 band, meanPP < 25) = 14/28 strain; else/partial (mean in 25–49 or 50–74) = 14/28 accent.
The mean capsule keeps its existing meterColor tone. Label contrast holds (no white text on a light wash).
Copy, accessibilityIdentifier, accessibilityLabel, hist bin math, and READY formula unchanged. No new SID.
SurfaceID: `fitbit.air.density.hist` / `health.air.density.hist`
Proof: `.audit/verify-density-hist.png`
