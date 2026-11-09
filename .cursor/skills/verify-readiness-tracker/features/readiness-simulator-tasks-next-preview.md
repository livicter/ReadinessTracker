# Simulator next READY-impact task preview

## Sub-features
- Capsule under lift progress showing the highest `readyDelta` unchecked task
- Tap checks that next task (`completedTaskIDs.insert(next.id)`)
- Hidden when no unchecked task remains (no else/complete branch)
- WHOOP wells: idle (`done == 0`, next exists) ghost/hairline 8/28 secondaryText; active negative (`done > 0 && next.readyDelta < 0`) 14/28 strain `FF375F`; active positive (`done > 0 && next.readyDelta >= 0`) 14/28 accent
- SurfaceID `sim.load.tasks.nextpreview`

## How to get to it (user POV)
Today → Load Simulator → Next-task preview capsule under remaining-lift progress (above the ceiling rail).

## Driving it with the harness
`testReadinessLoadSimulatorSurface` waits for `sim.load.tasks.nextpreview`, taps, `saveShot("verify-simulator-next-preview.png")`.

## Gotchas
This ship restyles chrome only; preview pick (highest readyDelta unchecked), tap-to-check, and hide-when-none-remain are unchanged.
