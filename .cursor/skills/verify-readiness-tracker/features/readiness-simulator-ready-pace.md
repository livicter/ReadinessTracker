# Simulator READY pace meter (Honest #589 / #731)

## Sub-features
- Pace gauge pp/task + projected-if-pace capsule
- WHOOP wells: idle (no checks) = ghost/hairline 8%/28%; active (some checks) = 14% fill + 28% hairline in accent; brisk (pace >= 3) = same active well but optimal tone
- SurfaceID `sim.load.ready.pace` (existing Honest #589; no new SID)

## How to get to it (user POV)
Today → Load Simulator → READY pace under impact ladder.

## Driving it with the harness
`testReadinessLoadSimulatorSurface` asserts SurfaceID near the Honest #589 / #731 block and `saveShot("verify-simulator-ready-pace.png")`.

## Gotchas
Hidden when task list empty.
This restyles existing `readyPaceMeter` chrome only. Keep speedometer icon, "READY pace" label, capsule (`No checks yet` / verb + pp/task), gradient track + needle, footer (Gained / eta / n done), padding(10), cornerRadius 12, SID, accessibilityIdentifier, accessibilityLabel ("READY pace \(verb), \(pace) per task"), animation, and READY formula (pace = gained/n, etaTasks from remainPts/pace).
Idle (no checks) uses ghost 8%/28% secondaryText; active uses 14% fill + 28% hairline (accent, or optimal if pace >= 3 / Brisk).
No new SurfaceID or READY formula.
