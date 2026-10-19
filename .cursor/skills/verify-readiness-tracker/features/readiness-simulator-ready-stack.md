# Simulator READY composition stack

## Sub-features
- Stacked bar: Base / Levers / Tasks / Room
- Live with scrub + checked tasks
- SurfaceID `sim.load.ready.stack`

## How to get to it (user POV)
Today → Load Simulator → READY stack under path spark.

## Driving it with the harness
`testReadinessLoadSimulatorSurface` asserts `sim.load.ready.stack`, `saveShot("verify-simulator-ready-stack.png")`.

## Gotchas
Lever/task segments can be 0 when no scrub/checks; headroom fills remainder to 100.
