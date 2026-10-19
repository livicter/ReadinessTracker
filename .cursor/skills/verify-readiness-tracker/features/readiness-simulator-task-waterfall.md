# Simulator READY task waterfall

## Sub-features
- Cumulative READY step chart across tasks
- Checked vs queued point tint
- SurfaceID `sim.load.tasks.waterfall`

## How to get to it (user POV)
Today → Load Simulator → Task waterfall under READY stack.

## Driving it with the harness
`testReadinessLoadSimulatorSurface` asserts waterfall SurfaceID and `saveShot("verify-simulator-task-waterfall.png")`.

## Gotchas
Needs ≥1 generated task; lives between composition stack and Fitbit air strip.
