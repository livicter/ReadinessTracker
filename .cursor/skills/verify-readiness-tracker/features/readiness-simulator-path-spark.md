# Simulator READY path spark

## Sub-features
- LineMark path: Base → Scrub → Tasks → Ceil
- Baseline rule + catmullRom interpolation
- SurfaceID `sim.load.path.spark`

## How to get to it (user POV)
Today → Load Simulator card → READY path chart under spark projection.

## Driving it with the harness
`testReadinessLoadSimulatorSurface` waits for `sim.load.path.spark`, taps, `saveShot("verify-simulator-path-spark.png")`.

## Gotchas
Path values depend on scrub + checked tasks; ceiling caps at 100.
