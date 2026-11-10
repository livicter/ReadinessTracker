# Honest #590 / #663 / #811: Density ACF₁ meter (WHOOP wells)

Chrome-only WHOOP wells on the existing density ACF₁ meter (`fitbit.air.density.acf` / `health.air.density.acf`).
The lag-1 −1…+1 gradient track, zero tick, and tone-filled needle already encode the ACF reading and are left intact (not flattened to a uniform 8/14 wash).
Idle (no density > 0 in the 14d window) = ghost/hairline 8/28 secondaryText; active complete (has density, Sticky or strong Flip, abs(acf) >= 0.5) = 14/28 optimal; active negative (Noise, abs(acf) < 0.2) = 14/28 strain; else/partial (Mild or mild Flip, 0.2 <= abs(acf) < 0.5) = 14/28 accent.
The verb capsule keeps its existing tone. Copy, accessibilityIdentifier, accessibilityLabel, ACF math, and READY formula unchanged.
SurfaceID: `fitbit.air.density.acf` / `health.air.density.acf`
Proof: UITest → `.audit/verify-density-acf.png`
