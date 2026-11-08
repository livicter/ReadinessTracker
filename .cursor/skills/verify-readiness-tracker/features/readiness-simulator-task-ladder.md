# Simulator task impact ladder (Honest #585 / #730)

## Sub-features
- Ranked READY-lift bars (top 6) with done state
- WHOOP wells: idle (no checks) = ghost/hairline 8%/28%; active (some checks) = 14% fill + 28% hairline in accent; all tasks checked = same active well but optimal tone
- SurfaceID `sim.load.tasks.ladder` (existing Honest #585; no new SID)

## How to get to it (user POV)
Today → Load Simulator → Impact ladder under task waterfall.

## Driving it with the harness
`testReadinessLoadSimulatorSurface` asserts SurfaceID near the Honest #585 / #730 block and `saveShot("verify-simulator-task-ladder.png")`.

## Gotchas
Hidden when no tasks.
This restyles existing `taskImpactLadderBody` chrome only. Keep ranking (top 6 by readyDelta desc), bar geometry, labels ("Impact ladder"), capsule (`All clear` / `+N left`), icons/checkmarks, +delta, padding(10), cornerRadius 12, SID, accessibilityIdentifier, accessibilityLabel ("Impact ladder \(remain) READY points remaining"), animation, and READY formula (remain = sum of pending readyDelta).
Idle (no checks) uses ghost 8%/28% secondaryText; active uses 14% fill + 28% hairline (accent, or optimal if all checked).
No new SurfaceID or READY formula.
