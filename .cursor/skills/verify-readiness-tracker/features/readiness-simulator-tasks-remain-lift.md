# Simulator remaining READY-lift gauge

## Sub-features
- Progress capsule under READY lift showing +checked/+total and remain (or done)
- Tap checks the next highest `readyDelta` unchecked task
- WHOOP wells: idle (`done == 0 && remain > 0`) ghost/hairline 8/28 secondaryText; active negative (`done > 0 && lift < 0`) 14/28 strain `FF375F`; active complete (`remain == 0`) 14/28 optimal; active partial (some checked, remain > 0, lift >= 0) 14/28 accent
- SurfaceID `sim.load.tasks.remainlift`

## How to get to it (user POV)
Today → Load Simulator → Lift progress capsule under READY lift (above the next-task preview).

## Driving it with the harness
`testReadinessLoadSimulatorSurface` waits for `sim.load.tasks.remainlift`, taps, `saveShot("verify-simulator-remain-lift.png")`.

## Gotchas
`remain` is leftover READY lift (`max(0, totalLift - lift)`), not a task count. This ship restyles chrome only; lift math, tap-to-check-next, and the inner progress rail are unchanged.
