# Simulator ring delta bars

## Sub-features
- BarMark Δ for READY/Gym/Work/Sleep
- Legend chips
- SurfaceID `sim.load.ring.deltas`

## How to get to it (user POV)
Today → Load Simulator → Ring deltas under task radial.

## Driving it with the harness
`testReadinessLoadSimulatorSurface` asserts ring.deltas SurfaceID and `saveShot("verify-simulator-ring-deltas.png")`.

## Gotchas
Always mounted; tracks lever scrubs + task lift.
