# Simulator READY pace meter

## Sub-features
- Pace gauge pp/task + projected-if-pace capsule
- SurfaceID `sim.load.ready.pace`

## How to get to it (user POV)
Today → Load Simulator → READY pace under impact ladder.

## Driving it with the harness
`testReadinessLoadSimulatorSurface` asserts SurfaceID and `saveShot("verify-simulator-ready-pace.png")`.

## Gotchas
Hidden when task list empty.
