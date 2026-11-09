# Simulator projected READY ceiling

## Sub-features
- Dual-rail now vs ceiling if all remaining tasks checked
- Fill/Done capsule checks all remaining tasks
- WHOOP wells: idle (no ordered tasks checked yet and remain > 0) ghost/hairline 8/28 secondaryText; active complete (`remain == 0`) 14/28 optimal; active partial (some checked, remain > 0) 14/28 accent; active negative (`ceilingReady < nowReady`) 14/28 strain `FF375F`
- SurfaceID `sim.load.tasks.ceiling`

## How to get to it (user POV)
Today → Load Simulator → Ceiling rail under next-task preview.

## Driving it with the harness
`testReadinessLoadSimulatorSurface` waits for `sim.load.tasks.ceiling`, taps, `saveShot("verify-simulator-tasks-ceiling.png")`.

## Gotchas
Ceiling caps at 100. `remain` is leftover READY lift (`totalLift - lift`), not task count. This ship restyles the card chrome only — ceiling math, check-all action, and dual-rail geometry are unchanged.
