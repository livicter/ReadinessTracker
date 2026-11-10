# Honest #529 / #686 / #793: Density stacked bar (WHOOP wells)

Chrome-only WHOOP wells on the existing density stacked bar (`fitbit.air.density.stack` / `health.air.density.stack`).
Idle (filled == 0) = ghost/hairline 8/28 using secondaryText; active complete (filled == total) = 14/28 optimal; else/partial = 14/28 accent. No negative state (fill is non-negative).
Copy, accessibilityIdentifier, accessibilityLabel, focus-toggle math, width/fill-ratio math, and READY formula unchanged.
SurfaceID: `fitbit.air.density.stack` / `health.air.density.stack`
Proof: UITest → `.audit/verify-density-stack.png`
