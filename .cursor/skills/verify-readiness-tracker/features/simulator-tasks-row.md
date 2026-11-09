# Simulator task rows (Honest #720 / #786)

## Sub-features
- Leading 3pt continuous rail: `RTColor.optimal` when done, otherwise the card accent
- Check well: circular tint chip (`checkmark.circle.fill` on optimal fill when done; accent-tinted circle well when not)
- Title uses `secondaryText` + strikethrough when done
- Keeps `+READY` capsule (white on optimal when done, accent otherwise), `task.icon`, and detail caption
- 0.2s easeInOut on `isDone`, matching the #719 / #785 bar animation
- WHOOP wells on the existing Honest #720 row: idle (`!isDone`) ghost/hairline 8/28 secondaryText; active complete (`isDone && readyDelta >= 0`) 14/28 optimal; active negative (`isDone && readyDelta < 0`) 14/28 strain (`Color(hex: "FF375F")`)
- SurfaceID `sim.load.tasks.row` (existing; no new SID)

## How to get to it (user POV)
Today → Load Simulator → scroll to Today’s tasks → individual task rows under the #719 / #785 segmented completion bar.

## Driving it with the harness
`testReadinessLoadSimulatorSurface` asserts `sim.load.tasks.row` near the Honest #499 tasks.progress / #719 / #785 tasks.bar block (fallback `sim.load.tasks` / `sim.load.md.nav`), keeps the existing row tap, and `saveShot("verify-simulator-tasks-row.png")`.

## Gotchas
This ship restyles the outer well chrome only — check-well icons, leading 3pt rail, `completedTaskIDs` toggle math, accessibilityIdentifier string, accessibilityLabel, READY formula, task list ordering, and the #785 bar are unchanged. Does not invent a new SID.
