# Honest #529 / #686 / #793: Density stacked bar (WHOOP wells)

Fitbit/Health on-card Sleep / Vitals / Move density category stacked bar.
Chrome-only WHOOP wells on the existing Honest #529 / #686 stack.
Idle (filled == 0) = ghost/hairline 8/28 using secondaryText; active complete (filled == total) = 14/28 optimal; else/partial = 14/28 accent. No negative state (fill is non-negative).
Copy, accessibilityIdentifier, accessibilityLabel, focus-toggle math, width/fill-ratio math, and READY formula unchanged. Focus keeps a thicker hairline. Solid 0.85/0.35 category fills and inverted white labels dropped so label contrast holds on the translucent well; category identity stays on the label color.
SurfaceID: `fitbit.air.density.stack` / `health.air.density.stack`
Proof: `.audit/verify-density-stack.png`
