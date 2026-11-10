# Honest #572 / #670 / #802: Density CV meter (WHOOP wells)

Fitbit/Health air density coefficient-of-variation meter immediately after the distribution hist on the Air card (below heatmap + WoW + forecast + streak + spark + hist; next unstyled meter body in the hist → gain/pain stack).
Chrome-only WHOOP wells on the existing Honest #572 / #670 CV meter container.
The ratio track already encodes the CV reading itself (barFrac = min(1, cv/0.5) fill plus meterColor→tone gradient). That track is left intact — not flattened to a uniform 8/14 wash.
Idle (no density > 0 in the 14d window) = ghost/hairline 8/28 secondaryText; active complete (has density, Stable, cvPP <= 15) = 14/28 optimal; active negative (Volatile, cvPP > 30) = 14/28 strain; else/partial (Mixed, 15 < cvPP <= 30) = 14/28 accent.
The stability capsule keeps its existing tone (Stable/optimal, Mixed/good, Volatile/warning). Label contrast holds (no white text on a light wash).
Copy, accessibilityIdentifier, accessibilityLabel, CV math, and READY formula unchanged. No new SID.
SurfaceID: `fitbit.air.density.cv` / `health.air.density.cv`
Proof: `.audit/verify-density-cv.png`
