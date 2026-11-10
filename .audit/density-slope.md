# Honest #586 / #665 / #809: Density slope meter (WHOOP wells)

Fitbit/Health air density 14d OLS slope meter, immediately after the Tukey fences on the Air card (below heatmap + WoW + forecast + streak + spark + hist + CV + skew + IQR + percentile + envelope + MAD + Tukey; next unstyled meter body in the hist → gain/pain stack is the z-score strip).
Chrome-only WHOOP wells on the existing Honest #586 / #665 slope meter container.
The dens spark PATH (meterColor 0.55) and dashed trend line (existing tone) already encode the signed slope. Those marks are left intact — not flattened to a uniform 8/14 wash.
Idle (no density > 0 in the 14d window) = ghost/hairline 8/28 secondaryText; active complete (has density, Stable, absPP < 0.4) = 14/28 optimal; active negative (Falling, absPP >= 0.4 && slopePP <= 0) = 14/28 strain; else/partial (Rising, absPP >= 0.4 && slopePP > 0) = 14/28 accent.
The verb capsule and pp/d footer keep their existing tones. Label contrast holds (no white text on a light wash).
Copy, accessibilityIdentifier, accessibilityLabel, slope math, and READY formula unchanged. No new SID.
SurfaceID: `fitbit.air.density.slope` / `health.air.density.slope`
Proof: `.audit/verify-density-slope.png`
