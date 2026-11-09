# Simulator controls (Honest #718 / #783)

## Sub-features
- WHOOP-parity bipolar sliders (center-zero tick + signed fill) and live per-lever READY Δ via `project()` vs all-zero
- WHOOP wells on the existing outer slider stack: idle (all five levers at 0) ghost/hairline 8/28 secondaryText; active negative (combined isolated READY Δ < 0) 14/28 strain; active positive (combined isolated READY Δ > 0) 14/28 optimal; active mixed (some nonzero levers whose isolated contributions cancel) 14/28 accent
- SurfaceID `sim.load.controls`

## How to get to it (user POV)
Today → Load Simulator card → scroll to the bipolar Sleep / HRV / Strain / RHR / SpO₂ sliders (always visible, below the projection gauge).

## Driving it with the harness
`testReadinessLoadSimulatorSurface` asserts `sim.load.controls` and `saveShot("verify-simulator-controls.png")`. The test taps the first slider, so the proof PNG is expected to show the active well.

## Gotchas
This ship restyles the outer well chrome only — slider internals, copy, header/capsule tints, identifiers, interaction, and accessibilityIdentifier are unchanged. Well tone follows `isolatedReadyDelta(sleep:hrv:strain:rhr:spo2:)` combined vs all-zero (same isolation as per-slider READY capsules). Idle = all five levers at 0. Mixed = some nonzero levers whose isolated contributions cancel (combined == 0). Do not invent a new SID.
