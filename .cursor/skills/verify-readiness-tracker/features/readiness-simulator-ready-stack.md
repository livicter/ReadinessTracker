# Simulator READY composition stack (Honest #563 / #728)

## Sub-features
- Stacked bar: Base / Levers / Tasks / Room
- Live with scrub + checked tasks
- WHOOP wells: idle (no lever/task lift) = ghost/hairline 8%/28%; active = 14% fill + 28% hairline (accent, or optimal if headroom==0)
- Track as a ghost well (secondaryText 8% fill + 28% hairline); existing Base/Levers/Tasks/Room fills and 2pt gaps
- SurfaceID `sim.load.ready.stack` (existing Honest #563; no new SID)

## How to get to it (user POV)
Today → Load Simulator → READY stack under path spark.

## Driving it with the harness
`testReadinessLoadSimulatorSurface` asserts SurfaceID near the Honest #563 / #728 block and `saveShot("verify-simulator-ready-stack.png")`.

## Gotchas
Lever/task segments can be 0 when no scrub/checks; headroom fills remainder to 100.
This restyles existing `readyCompositionStack` chrome only. Keep labels, capsule "N/100", formula, segment colors, accessibility identifier/label.
Idle (leverLift==0 && taskLift==0) uses ghost 8%/28%; active uses 14% fill + 28% hairline.
No new SurfaceID or READY formula.
