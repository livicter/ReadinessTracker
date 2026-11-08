# Simulator READY task waterfall (Honest #565 / #729)

## Sub-features
- Cumulative READY step chart across tasks
- Checked vs queued point tint
- WHOOP wells: idle (no checks) = ghost/hairline 8%/28%; active (some checks) = 14% fill + 28% hairline in accent; all tasks checked = same active well but optimal tone
- SurfaceID `sim.load.tasks.waterfall` (existing Honest #565; no new SID)

## How to get to it (user POV)
Today → Load Simulator → Task waterfall under READY stack.

## Driving it with the harness
`testReadinessLoadSimulatorSurface` asserts waterfall SurfaceID near the Honest #565 / #729 block and `saveShot("verify-simulator-task-waterfall.png")`.

## Gotchas
Needs ≥1 generated task; lives between composition stack and Fitbit air strip.
This restyles existing `taskWaterfallBody` chrome only. Keep chart marks/interpolation, labels ("Task waterfall", capsule `projected→ceiling`), Checked/Queued legend, padding, SID, accessibilityIdentifier, accessibilityLabel, and the READY formula (`projected` + cumulative `task.readyDelta`, ceiling = last step ready).
Idle (no checks) uses ghost 8%/28% secondaryText; active uses 14% fill + 28% hairline (accent, or optimal if all checked).
No new SurfaceID or READY formula.
