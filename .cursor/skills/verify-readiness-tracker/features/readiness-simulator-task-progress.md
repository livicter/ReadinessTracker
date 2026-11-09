# Simulator task progress (Honest #499 / #779)

## Sub-features
- Task progress count capsule (`done/ordered.count`) on Today’s Load Simulator
- WHOOP wells on the existing progress count: idle (done == 0) ghost/hairline 8/28 secondaryText; active complete (done == ordered.count && ordered.count > 0) 14/28 optimal; else (partial) 14/28 accent
- SurfaceID `sim.load.tasks.progress`

## How to get to it (user POV)
Today → Load Simulator card → scroll to Today’s tasks → progress count capsule immediately after the Undo last button (always visible).

## Driving it with the harness
`testReadinessLoadSimulatorSurface` asserts `sim.load.tasks.progress` (or the tasks surface) and `saveShot("verify-simulator-tasks-progress.png")`.

## Gotchas
This ship restyles the capsule chrome only — visibility, copy (`done/ordered.count`), and accessibilityIdentifier are unchanged. Idle (`done == 0`) is checked before complete so an empty task list does not render as optimal. Do not restyle `sim.load.tasks.bar` (#719) or `sim.load.tasks.row` (#720); those already have WHOOP-parity chrome.
