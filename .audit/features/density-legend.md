# Honest #513 / #690 / #709 / #710 / #711 / #792: Density legend pills (WHOOP wells)

Chrome-only WHOOP wells on the existing density legend pills (`fitbit.air.density.legend` / `health.air.density.legend` inner `fitbit.air.legend.*` / `health.air.legend.*` pills).
Idle (filled == 0) = ghost/hairline 8/28 using secondaryText; active complete (filled == total) = 14/28 optimal; else/partial = 14/28 accent. No negative state (fill is non-negative).
Copy, accessibilityIdentifier, accessibilityLabel, focus-toggle math, and READY formula unchanged.
SurfaceID: `fitbit.air.density.legend` / `health.air.density.legend` / `fitbit.air.legend.*` / `health.air.legend.*`
Proof: UITest → `.audit/verify-density-legend.png`
