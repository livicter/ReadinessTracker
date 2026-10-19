# Simulator seed vs live delta rail

## Sub-features
- Seed vs live READY numbers + delta capsule
- Dual-rail gauge
- Optional Fitbit/Google Health air density cue
- SurfaceID `sim.load.seed.delta`

## How to get to it (user POV)
Today → Load Simulator → Seed vs live under READY zones.

## Driving it with the harness
`testReadinessLoadSimulatorSurface` asserts seed.delta SurfaceID and `saveShot("verify-simulator-seed-delta.png")`.

## Gotchas
Always mounted; air density line shows when FitbitAirChip data exists.
