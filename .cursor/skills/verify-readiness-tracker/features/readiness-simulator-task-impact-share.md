# Simulator task impact share stack

## Sub-features
- Proportional share bar + secured % capsule
- SurfaceID `sim.load.tasks.impactshare`

## How to get to it (user POV)
Today → Load Simulator → Impact share under READY pace.

## Driving it with the harness
`testReadinessLoadSimulatorSurface` asserts SurfaceID and `saveShot("verify-simulator-task-impact-share.png")`.

## Gotchas
Hidden when task list empty.
