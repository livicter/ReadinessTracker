# Honest #514 / #689 / #799: Density history spark (WHOOP wells)

Fitbit/Health air density history spark under the streak badge (below heatmap + WoW + forecast).
Chrome-only WHOOP wells on the existing Honest #514 / #689 spark container.
The spark PATH already encodes history (AreaMark 0.18, LineMark, PointMark, mean RuleMark) and is left intact — not flattened to a uniform 8/14 wash.
Idle (no density > 0 in the window) = ghost/hairline 8/28 secondaryText; else/partial (has history) = 14/28 accent.
No natural complete/negative state — a history path is not a fill-complete or up/down badge.
Mean and range capsules keep their existing tones. Label contrast holds (no white text on a light wash).
Copy, accessibilityIdentifier, accessibilityLabel, scrub/period math, and READY formula unchanged. No new SID.
SurfaceID: `fitbit.air.density.spark` / `health.air.density.spark`
Proof: `.audit/verify-density-spark.png`
