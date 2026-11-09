# Honest #718 / #783: Simulator controls (WHOOP wells)

WHOOP-parity bipolar sliders (center-zero tick + signed fill) and live per-lever READY Δ via `project()` vs all-zero.
Chrome-only WHOOP wells on the existing outer slider stack.
Idle (all five levers at 0) = ghost/hairline 8/28 using secondaryText; active negative (combined isolated READY Δ < 0) = 14/28 strain; active positive (combined isolated READY Δ > 0) = 14/28 optimal; active mixed (some nonzero levers whose isolated contributions cancel) = 14/28 accent.
Slider internals, copy, tints, identifiers, interaction, and accessibilityIdentifier unchanged.
SurfaceID: `sim.load.controls`
Proof: `.audit/verify-simulator-controls.png`
