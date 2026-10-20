# Simulator task impact ladder

## Sub-features
- Ranked READY-lift bars (top 6) with done state
- SurfaceID `sim.load.tasks.ladder`

## How to get to it (user POV)
Today → Load Simulator → Impact ladder under task waterfall.

## Driving it with the harness
`testReadinessLoadSimulatorSurface` asserts SurfaceID and `saveShot("verify-simulator-task-ladder.png")`.

## Gotchas
Hidden when no tasks.
