# Simulator READY path zone bands

## Sub-features
- Base→Scrub→Tasks→Ceil ticks on zone rail
- SurfaceID `sim.load.path.zones`

## How to get to it (user POV)
Today → Load Simulator → path zone bands near READY path spark.

## Driving it with the harness
`testReadinessLoadSimulatorSurface` asserts SurfaceID and `saveShot("verify-simulator-path-zone-bands.png")`.

## Gotchas
Always mounts with path spark.
