# Simulator task rows (Honest #720)

## Sub-features
- Leading 3pt continuous rail: `RTColor.optimal` when done, otherwise the card accent
- Check well: circular tint chip (`checkmark.circle.fill` on optimal fill when done; accent-tinted circle well when not)
- Stronger done state: title uses `secondaryText` + strikethrough; row fill optimal ~12% vs undone `surfaceHighlight` 0.65
- Keeps `+READY` capsule (white on optimal when done, accent otherwise), `task.icon`, and detail caption
- 0.2s easeInOut on `isDone`, matching the #719 bar animation
- SurfaceID `sim.load.tasks.row` (existing; no new SID)

## How to get to it (user POV)
Today → Load Simulator → scroll to Today’s tasks → individual task rows under the #719 segmented completion bar.

## Driving it with the harness
`testReadinessLoadSimulatorSurface` asserts `sim.load.tasks.row` near the Honest #499 tasks.progress / #719 tasks.bar block (fallback `sim.load.tasks` / `sim.load.md.nav`), keeps the existing row tap, and `saveShot("verify-simulator-tasks-row.png")`.

## Gotchas
This restyles the existing row only; the segmented completion bar was Honest #719 (`sim.load.tasks.bar`). Toggle still writes the same `completedTaskIDs` set — no new READY formula and no new SurfaceID.
