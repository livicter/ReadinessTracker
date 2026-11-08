# Simulator seed air (Honest #722)

## Sub-features
- Full-width WHOOP action well for Seed from Fitbit/Health air
- Idle (`airSeededSummary == nil`) = ghost/hairline well (accent 8% fill + 28% hairline) with caption/caption2 bold label in secondaryText
- Seeded (`airSeededSummary != nil`) = filled accent well + white label (same as selected non-Reset preset)
- Keep wind SF Symbol, existing titles, and the "7d Δ" capsule (capsule fill contrasts on both idle and seeded)
- 0.2s easeInOut keyed on whether airSeededSummary is set, matching #721
- SurfaceID `sim.load.seed.air` (existing Honest #518; no new SID)

## How to get to it (user POV)
Today → Load Simulator → Seed from Fitbit/Health air button directly under the #721 Rest/Easy/Push/Reset preset wells, above the Honest #547 density-forecast button.

## Driving it with the harness
`testReadinessLoadSimulatorSurface` asserts `sim.load.seed.air` near the Honest #518 block (fallback "Seed from" label), taps the well, and `saveShot("verify-simulator-seed-air.png")` alongside `verify-readiness-load-simulator-seed-air.png`.

## Gotchas
This restyles the existing seed-from-air button only; `seedFromAir()` lever math stays Honest #518. Do not restyle `sim.load.seed.forecast` (#547). No new SurfaceID or READY formula.
