# Simulator lever deltas (Honest #516 / #780)

## Sub-features
- Per-lever READY contribution chips (interactive) on Today’s Load Simulator
- WHOOP wells on the existing outer chip stack: idle (all contributions == 0) ghost/hairline 8/28 secondaryText; active negative (sum < 0) 14/28 strain; active positive (sum > 0) 14/28 optimal; active mixed (sum == 0 but some nonzero) 14/28 accent
- SurfaceID `sim.load.delta.levers`

## How to get to it (user POV)
Today → Load Simulator card → scroll to Lever deltas chips (always visible, above Lever sensitivity).

## Driving it with the harness
`testReadinessLoadSimulatorSurface` asserts `sim.load.delta.levers` (or the “Lever deltas” label) and `saveShot("verify-readiness-load-simulator-lever-deltas.png")`.

## Gotchas
This ship restyles the outer well chrome only — copy, chip interaction, visibility, accessibilityIdentifier, and accessibilityLabel are unchanged. Individual `leverDeltaChip` fills are not restyled. Do not restyle `sim.load.lever.sensitivity` (#567 / #764); that sibling already has WHOOP wells on the same per-lever `contribution(...)` data. Displayed Σ text still uses `deltaVsBaseline` (not the local `sum` used only for well tone).
