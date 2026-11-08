# Simulator seed forecast (Honest #723)

## Sub-features
- Full-width WHOOP action well for Seed from density forecast
- Idle (summary does not start with "Seeded from forecast") = ghost/hairline well (accent 8% fill + 28% hairline) with caption bold label in secondaryText
- Forecast-seeded (`airSeededSummary` has prefix "Seeded from forecast") = filled accent well + white label (same as #722 seeded air well)
- Keep sparkles SF Symbol, existing title, and the "tmrw" capsule (capsule fill contrasts on both idle and seeded)
- 0.2s easeInOut keyed on whether the forecast seed prefix is set, matching #721/#722
- SurfaceID `sim.load.seed.forecast` (existing Honest #547; no new SID)
- Failed guard ("Need ≥3 days of air history for forecast") stays idle, not filled

## How to get to it (user POV)
Today → Load Simulator → Seed from density forecast button directly under the #722 seed-from-air well.

## Driving it with the harness
`testReadinessLoadSimulatorSurface` asserts `sim.load.seed.forecast` near the Honest #547 block (fallback "Seed from density forecast" label), taps the well, and `saveShot("verify-simulator-seed-forecast.png")` alongside `verify-readiness-load-simulator-seed-forecast.png`.

## Gotchas
This restyles the existing seed-from-forecast button only; `seedFromDensityForecast()` lever math stays Honest #547. Do not restyle `sim.load.seed.air` (#722). No new SurfaceID or READY formula.
