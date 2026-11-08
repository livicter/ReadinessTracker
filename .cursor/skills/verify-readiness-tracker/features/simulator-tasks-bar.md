# Simulator task completion bar (Honest #719)

## Sub-features
- Segmented track: one segment per visible task, filled when that task is in `completedTaskIDs`
- Fallback proportional fill `done` / `tasks.count` when `ordered` is empty
- Caption `N/M` and percent from existing counts
- Tint `RTColor.optimal` when all done, otherwise the card accent
- SurfaceID `sim.load.tasks.bar`

## How to get to it (user POV)
Today → Load Simulator → scroll to Today’s tasks → completion bar above the task rows.

## Driving it with the harness
`testReadinessLoadSimulatorSurface` asserts `sim.load.tasks.bar` near the Honest #499 tasks.progress / tasks.row block (fallback `sim.load.tasks` / `sim.load.md.nav`) and `saveShot("verify-simulator-tasks-bar.png")`.

## Gotchas
Does not restyle task rows (`sim.load.tasks.row` is the next sibling). Check-all / row taps update the same `completedTaskIDs` the bar already reads — no new READY formula.
