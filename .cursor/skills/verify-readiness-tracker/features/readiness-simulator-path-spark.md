# Simulator READY path spark

## Sub-features
- LineMark path: Base → Scrub → Tasks → Ceil
- Baseline rule + catmullRom interpolation
- WHOOP wells: idle (path flat at baseline) ghost/hairline 8/28 secondaryText; active negative (`ceiling < baseline`) 14/28 strain `FF375F`; active positive (`ceiling > baseline`) 14/28 optimal; active mixed (moved but `ceiling == baseline`) 14/28 accent
- SurfaceID `sim.load.path.spark`

## How to get to it (user POV)
Today → Load Simulator card → READY path chart under spark projection.

## Driving it with the harness
`testReadinessLoadSimulatorSurface` waits for `sim.load.path.spark`, taps, `saveShot("verify-simulator-path-spark.png")`.

## Gotchas
Path values depend on scrub + checked tasks; ceiling caps at 100. This ship restyles the card chrome only — path math is unchanged.
