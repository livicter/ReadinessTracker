# Honest #513 / #690 / #709 / #710 / #711 / #792: Density legend pills (WHOOP wells)

Fitbit/Health on-card Sleep / Vitals / Activity density legend pills (and the density.legend container).
Chrome-only WHOOP wells on the existing Honest #513 / #690 / #709 / #710 / #711 pills.
Idle (filled == 0) = ghost/hairline 8/28 using secondaryText; active complete (filled == total) = 14/28 optimal; else/partial = 14/28 accent. No negative state (fill is non-negative).
Copy, accessibilityIdentifier, accessibilityLabel, focus-toggle math, spark-link behavior, and READY formula unchanged. Focus keeps a thicker hairline; inverted white-on-solid fill dropped so label contrast holds on the translucent well.
SurfaceID: `fitbit.air.density.legend` / `health.air.density.legend` / `fitbit.air.legend.*` / `health.air.legend.*`
Proof: `.audit/verify-density-legend.png`
