# Simulator task impact share stack (Honest #591 / #732)

## Sub-features
- Proportional share bar + secured % capsule
- WHOOP wells: idle (no checks) = ghost/hairline 8%/28%; active (some checks) = 14% fill + 28% hairline in accent; all tasks checked = same active well but optimal tone
- SurfaceID `sim.load.tasks.impactshare` (existing Honest #591; no new SID)

## How to get to it (user POV)
Today → Load Simulator → Impact share under READY pace.

## Driving it with the harness
`testReadinessLoadSimulatorSurface` asserts SurfaceID near the Honest #591 / #732 block and `saveShot("verify-simulator-task-impact-share.png")`.

## Gotchas
Hidden when task list empty.
This restyles existing `taskImpactShareBody` chrome only. Keep chart.bar.doc.horizontal.fill icon, "Impact share" label, capsule (`pct% · +secured/+total`), proportional share bar geometry, +delta overlays, footer (Top N = +X / share of lift), padding(10), cornerRadius 12, SID, accessibilityIdentifier, accessibilityLabel ("Impact share \(pct) percent, secured +\(secured) of +\(total)"), animation, and READY formula (secured/total * 100).
Idle (no checks) uses ghost 8%/28% secondaryText; active uses 14% fill + 28% hairline (accent, or optimal if all checked).
No new SurfaceID or READY formula.
