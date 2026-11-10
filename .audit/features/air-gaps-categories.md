# Honest #554 / #637 / #790: Fitbit/Health air-gaps category gauges (WHOOP wells)

Chrome-only WHOOP wells on the existing Fitbit/Health air-gaps category gauges (`fitbit.air.gaps.categories` / `health.air.gaps.categories`).
Idle (filled == 0) = ghost/hairline 8/28 using secondaryText; active complete (filled == total) = 14/28 optimal; else/partial = 14/28 accent. No negative state (fill is non-negative).
Focus keeps a thicker hairline. Copy, accessibilityIdentifier, accessibilityLabel, toggle math, and READY formula unchanged. Health twin keeps #637 parity.
SurfaceID: `fitbit.air.gaps.categories` / `health.air.gaps.categories`
Proof: UITest → `.audit/verify-air-gaps-categories.png`
