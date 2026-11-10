# Honest #590 / #663 / #811: Density ACF₁ meter (WHOOP wells)

Fitbit/Health air density lag-1 autocorrelation meter, immediately after the z-score strip on the Air card (below heatmap + WoW + forecast + streak + spark + hist + CV + skew + IQR + percentile + envelope + MAD + Tukey + slope + z-score; next unstyled meter body in the hist → gain/pain stack is the entropy meter).
Chrome-only WHOOP wells on the existing Honest #590 / #663 ACF₁ meter container.
The lag-1 −1…+1 gradient track, zero tick, and tone-filled needle already encode the ACF reading. Those marks are left intact — not flattened to a uniform 8/14 wash.
Idle (no density > 0 in the 14d window) = ghost/hairline 8/28 secondaryText; active complete (has density, Sticky or strong Flip, abs(acf) >= 0.5) = 14/28 optimal; active negative (Noise, abs(acf) < 0.2) = 14/28 strain; else/partial (Mild or mild Flip, 0.2 <= abs(acf) < 0.5) = 14/28 accent.
Flip is not automatically strain: strong Flip (acf <= -0.5) is complete/optimal per the existing tone. The verb capsule keeps its existing tone. Label contrast holds (no white text on a light wash).
Copy, accessibilityIdentifier, accessibilityLabel, ACF math, and READY formula unchanged. No new SID.
SurfaceID: `fitbit.air.density.acf` / `health.air.density.acf`
Proof: `.audit/verify-density-acf.png`
