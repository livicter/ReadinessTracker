# Simulator gauge (Honest #717 / #784)

## Sub-features
- WHOOP-parity zone-banded projection gauge (Poor·Fair·Good·Optimal arcs + baseline tick + Δ chip)
- WHOOP wells on the existing circular gauge: idle (focused-ring delta vs tonight baseline == 0) ghost/hairline 8/28 secondaryText; active negative (delta < 0) 14/28 strain; active positive (delta > 0) 14/28 optimal
- SurfaceID `sim.load.gauge`

## How to get to it (user POV)
Today → Load Simulator card → the circular projection gauge at the top of the card (always visible, above the bipolar sliders).

## Driving it with the harness
`testReadinessLoadSimulatorSurface` asserts `sim.load.gauge` (with `sim.load.ring.tint` / `sim.load.md.nav` fallbacks) and `saveShot("verify-simulator-gauge.png")`. That shot runs before the test swipes controls on-screen, so the PNG may still show the Today readiness card above the simulator; UITest green is the binding proof.

## Gotchas
This ship restyles the outer well chrome only — zone arcs, baseline tick, live fill, copy, identifiers, interaction, and accessibilityIdentifier are unchanged. Well tone follows `focusedRingValue - baseline` (same signed delta already shown on the gauge Δ chip). Idle = no projection change. The same ZStack also carries `sim.load.ring.tint`; do not invent a new SID or retarget that identifier.
