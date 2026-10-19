# Simulator READY zone strip

## Sub-features
- Four-tone zone band
- Live score marker
- SurfaceID `sim.load.ready.zones`

## How to get to it (user POV)
Today → Load Simulator → READY zones under path spark.

## Driving it with the harness
`testReadinessLoadSimulatorSurface` asserts zones SurfaceID and `saveShot("verify-simulator-ready-zones.png")`.

## Gotchas
Always mounted; tracks projectedCoupled.
