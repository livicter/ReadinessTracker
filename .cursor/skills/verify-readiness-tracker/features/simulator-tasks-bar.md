# Simulator task completion bar (Honest #719 / #785)

## Sub-features
- Segmented track: one segment per visible task, filled when that task is in `completedTaskIDs`
- Fallback proportional fill `done` / `tasks.count` when `ordered` is empty
- Caption `N/M` and percent from existing counts
- Tint `RTColor.optimal` when all done, otherwise the card accent
- WHOOP wells on the existing Honest #719 HStack: idle (`taskTotal == 0` OR `done == 0` / none checked) ghost/hairline 8/28 secondaryText; active complete (`allTasksDone`) 14/28 optimal; else (partial progress, some but not all checked) 14/28 accent
- SurfaceID `sim.load.tasks.bar`

## How to get to it (user POV)
Today → Load Simulator → scroll to Today’s tasks → completion bar above the task rows.

## Driving it with the harness
`testReadinessLoadSimulatorSurface` asserts `sim.load.tasks.bar` near the Honest #499 tasks.progress / tasks.row block (fallback `sim.load.tasks` / `sim.load.md.nav`) and `saveShot("verify-simulator-tasks-bar.png")`.

## Gotchas
This ship restyles the outer well chrome only — segment fill math (`barTint = allTasksDone ? RTColor.optimal : accent`, filled vs 0.18 opacity), caption `N/M` + percent, interaction, accessibilityLabel, accessibilityIdentifier string, READY formula, and `completedTaskIDs` toggle math are unchanged. Does not restyle task rows (`sim.load.tasks.row` is the next sibling). Check-all / row taps update the same `completedTaskIDs` the bar already reads — no new READY formula.
