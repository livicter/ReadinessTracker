# Simulator tasks air-gap filter

## Sub-features
- Toggle Today’s tasks between all tasks and air-gap (Fitbit/Health) tasks only
- WHOOP wells: idle (filter off / All) ghost/hairline 8/28 secondaryText; active (filter on / Air) 14/28 accent
- SurfaceID `sim.load.tasks.airfilter`

## How to get to it (user POV)
Today → Load Simulator card → scroll to Today’s tasks → All/Air capsule among the task chrome controls.

## Driving it with the harness
`testReadinessLoadSimulatorSurface` waits for `sim.load.tasks.airfilter`, taps it, `saveShot("verify-readiness-load-simulator-tasks-airfilter.png")`.

## Gotchas
This ship restyles the capsule chrome only — All/Air toggle math is unchanged.
