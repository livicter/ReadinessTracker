# Simulator task READY lift spark

## Sub-features
- Cumulative READY lift BarMark spark (per-task `readyDelta`; bars tint when checked)
- WHOOP wells: idle (no checked lift contributions: `lift == 0` and nothing checked, or every checked `readyDelta == 0`) ghost/hairline 8/28 secondaryText; active negative (`lift < 0`) 14/28 strain `FF375F`; active positive (`lift > 0`) 14/28 optimal; active mixed (some checked nonzero AND `lift == 0`) 14/28 accent
- SurfaceID `sim.load.tasks.liftspark`

## How to get to it (user POV)
Today → Load Simulator card → scroll to Today’s tasks → READY lift spark under the ceiling well.

## Driving it with the harness
`testReadinessLoadSimulatorSurface` waits for `sim.load.tasks.liftspark`, `saveShot("verify-readiness-load-simulator-task-lift-spark.png")`.

## Gotchas
Bar values are each task’s `readyDelta`; `lift` is the sum of checked `readyDelta`s. This ship restyles the card chrome only — bar-value math and bar tint are unchanged.
