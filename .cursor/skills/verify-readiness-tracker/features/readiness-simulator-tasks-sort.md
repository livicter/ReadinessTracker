# Simulator tasks sort by impact

## Sub-features
- Toggle Today’s tasks between default order and READY-impact descending
- WHOOP wells: idle (sort off / Sort) ghost/hairline 8/28 secondaryText; active (sort on / Impact ↓) 14/28 accent
- SurfaceID `sim.load.tasks.sort`

## How to get to it (user POV)
Today → Load Simulator card → scroll to Today’s tasks → Sort/Impact ↓ capsule among the task chrome controls.

## Driving it with the harness
`testReadinessLoadSimulatorSurface` waits for `sim.load.tasks.sort`, taps it, `saveShot("verify-readiness-load-simulator-tasks-sort.png")`.

## Gotchas
This ship restyles the capsule chrome only — sort toggle math is unchanged.
