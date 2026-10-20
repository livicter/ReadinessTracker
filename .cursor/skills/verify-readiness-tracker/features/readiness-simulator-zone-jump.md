# Simulator zone jump rail

## Sub-features
- Dual-tick zone band Base→Now + climb/slip capsule
- SurfaceID `sim.load.zone.jump`

## How to get to it (user POV)
Today → Load Simulator → Zone jump under READY zones.

## Driving it with the harness
`testReadinessLoadSimulatorSurface` asserts SurfaceID and `saveShot("verify-simulator-zone-jump.png")`.

## Gotchas
Always mounts.
