# Honest #631 / #633 / #635 / #791: Density category overlay chips (WHOOP wells)

Chrome-only WHOOP wells on the existing density category overlay chips (`health.air.density.cats` / `fitbit.air.density.detail.cats` / `health.air.density.detail.cats`).
Idle (filled == 0) = ghost/hairline 8/28 using secondaryText; active complete (filled == total) = 14/28 optimal; else/partial = 14/28 accent. No negative state (fill is non-negative).
Copy, accessibilityIdentifier, accessibilityLabel, visibility-toggle math, and READY formula unchanged.
SurfaceID: `health.air.density.cats` / `fitbit.air.density.detail.cats` / `health.air.density.detail.cats`
Proof: UITest → `.audit/verify-density-cats.png`
