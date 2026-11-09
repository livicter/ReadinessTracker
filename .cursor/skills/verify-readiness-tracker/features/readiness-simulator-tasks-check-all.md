# Simulator tasks check-all (Honest #539 / #776)

## Sub-features
- One-tap Check all / Clear of Today’s tasks (checks remaining, or clears when all are already checked)
- WHOOP wells: idle (no tasks) ghost/hairline 8/28 secondaryText; active complete (Clear / all checked) 14/28 optimal; active negative (ordered lift < 0, not complete) 14/28 strain `FF375F`; else (Check all) 14/28 accent
- SurfaceID `sim.load.tasks.checkall`

## How to get to it (user POV)
Today → Load Simulator card → scroll to Today’s tasks → Check all / Clear capsule among the task chrome controls.

## Driving it with the harness
`testReadinessLoadSimulatorSurface` waits for `sim.load.tasks.checkall`, taps it, `saveShot("verify-readiness-load-simulator-tasks-check-all.png")`.

## Gotchas
This ship restyles the capsule chrome only — Check all / Clear math, labels, and accessibilityIdentifier are unchanged.
