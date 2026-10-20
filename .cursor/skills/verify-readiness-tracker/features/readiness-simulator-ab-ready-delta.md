# Simulator A/B READY delta gauge

## Sub-features
- Dual-tick span gauge A/Base vs B/Live
- SurfaceID `sim.load.ab.ready.delta`

## How to get to it (user POV)
Today → Load Simulator → A/B READY Δ under lever polarity.

## Driving it with the harness
`testReadinessLoadSimulatorSurface` asserts SurfaceID and `saveShot("verify-simulator-ab-ready-delta.png")`.

## Gotchas
Always mounts (falls back to Base→Live when no snap A).
