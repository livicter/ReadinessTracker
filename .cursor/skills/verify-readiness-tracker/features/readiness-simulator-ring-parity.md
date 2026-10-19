# Simulator ring parity meters

## Sub-features
- Dual-track baseline ghost + live fill
- Per-ring tick at tonight baseline
- SurfaceID `sim.load.ring.parity`

## How to get to it (user POV)
Today → Load Simulator → Ring parity under ring deltas.

## Driving it with the harness
`testReadinessLoadSimulatorSurface` asserts parity SurfaceID and `saveShot("verify-simulator-ring-parity.png")`.

## Gotchas
None — always mounts when simulator card mounts.
