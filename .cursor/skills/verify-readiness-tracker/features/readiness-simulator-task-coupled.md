# Simulator task-coupled projection

## Sub-features
- Checked-task READY lift folded into the projection gauge
- Capsule chip ("Tasks +N" / "Tasks → gauge" · coupled)
- WHOOP wells: idle (`taskReadyLift == 0`) ghost/hairline 8/28 secondaryText; active negative (`taskReadyLift < 0`) 14/28 strain `FF375F`; active positive (`taskReadyLift > 0`) 14/28 optimal
- SurfaceID `sim.load.tasks.coupled`

## How to get to it (user POV)
Today → Load Simulator → projection hero chip next to the gauge.

## Driving it with the harness
`testReadinessLoadSimulatorSurface` asserts tasks.coupled SurfaceID and `saveShot("verify-readiness-load-simulator-task-coupled.png")`.

## Gotchas
Always mounted in the projection hero. Lift is the signed sum of checked-task `readyDelta`; this ship restyles the chip only — projection math is unchanged.
