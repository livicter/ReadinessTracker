# Simulator air-gap tasks (Honest #523 / #777)

## Sub-features
- Cue strip counting Fitbit/Health air-gap tasks (ids prefixed with `air-` or containing `air`)
- WHOOP wells on the existing Fitbit/Health source capsule plus row foreground: idle (count > 0 && done == 0) ghost/hairline 8/28 secondaryText; active complete (done == count) 14/28 optimal; active negative (air-gap readyDelta sum < 0, not complete) 14/28 strain `FF375F`; else (partial) 14/28 accent
- SurfaceID `sim.load.tasks.airgaps`

## How to get to it (user POV)
Today → Load Simulator card → scroll to Today’s tasks → air-gap task cue under the task chrome (shown only when air-gap tasks exist).

## Driving it with the harness
`testReadinessLoadSimulatorSurface` waits for `sim.load.tasks.airgaps` (optional when gaps exist in fixture) and `saveShot("verify-readiness-load-simulator-airgap-tasks.png")`.

## Gotchas
This ship restyles the cue chrome only — visibility, count math, copy, accessibilityIdentifier, and accessibilityLabel are unchanged. `airGapTasks(...)` generation is unchanged.
