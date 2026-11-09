# Simulator task READY impact (Honest #515 / #778)

## Sub-features
- Cumulative READY lift capsule from checked tasks on Today’s Load Simulator
- WHOOP wells on the existing READY lift capsule: idle (lift == 0) ghost/hairline 8/28 secondaryText; active complete (done == ordered.count) 14/28 optimal; active negative (lift < 0) 14/28 strain `FF375F`; else (partial, lift > 0) 14/28 accent
- SurfaceID `sim.load.tasks.impact`

## How to get to it (user POV)
Today → Load Simulator card → scroll to Today’s tasks → READY lift capsule under the task chrome (always visible).

## Driving it with the harness
`testReadinessLoadSimulatorSurface` waits for `sim.load.tasks.impact` (or the "READY lift" label) and `saveShot("verify-readiness-load-simulator-task-impact.png")`.

## Gotchas
This ship restyles the capsule chrome only — visibility, copy (`Tap tasks` / `+N`), accessibilityIdentifier, and accessibilityLabel are unchanged. Per-row `+N` capsules are unchanged.
