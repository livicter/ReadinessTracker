# Simulator tasks Top 3 READY-impact

## Sub-features
- One-tap check of the three highest READY-impact tasks (toggles off if all three are already checked)
- WHOOP wells: idle (empty top-3) ghost/hairline 8/28 secondaryText; active complete (all top-3 checked) 14/28 optimal; active negative (top-3 lift < 0) 14/28 strain `FF375F`; active partial 14/28 accent
- SurfaceID `sim.load.tasks.top3`

## How to get to it (user POV)
Today → Load Simulator card → scroll to Today’s tasks → Top 3 capsule among the task chrome controls.

## Driving it with the harness
`testReadinessLoadSimulatorSurface` waits for `sim.load.tasks.top3`, taps it, `saveShot("verify-readiness-load-simulator-tasks-top3.png")`.

## Gotchas
This ship restyles the capsule chrome only — check/uncheck math is unchanged.
