# Simulator task completion radial

## Sub-features
- AngularGradient donut of lift progress
- Done/Left legend
- SurfaceID `sim.load.tasks.radial`

## How to get to it (user POV)
Today → Load Simulator → Task radial under seed vs live.

## Driving it with the harness
`testReadinessLoadSimulatorSurface` asserts tasks.radial SurfaceID and `saveShot("verify-simulator-task-radial.png")`.

## Gotchas
Always mounted when tasks exist (empty tasks still show 0%).
