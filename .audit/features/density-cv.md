# Honest #572 / #670 / #802: Density CV meter (WHOOP wells)

Chrome-only WHOOP wells on the existing density CV meter (`fitbit.air.density.cv` / `health.air.density.cv`).
The ratio track already encodes the CV reading itself (barFrac = min(1, cv/0.5) fill plus meterColor→tone gradient) and is left intact (not flattened to a uniform 8/14 wash).
Idle (no density > 0 in the 14d window) = ghost/hairline 8/28 secondaryText; active complete (has density, Stable, cvPP <= 15) = 14/28 optimal; active negative (Volatile, cvPP > 30) = 14/28 strain; else/partial (Mixed, 15 < cvPP <= 30) = 14/28 accent.
Stability capsule keeps its existing tone. Copy, accessibilityIdentifier, accessibilityLabel, CV math, and READY formula unchanged.
SurfaceID: `fitbit.air.density.cv` / `health.air.density.cv`
Proof: UITest → `.audit/verify-density-cv.png`
