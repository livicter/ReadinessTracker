# Simulator READY path zone bands

## Sub-features
- Zone-colored rail + path ticks Base/Scrub/Tasks/Ceil
- SurfaceID `sim.load.path.zones`

## How to get to it (user POV)
Today → Load Simulator → Path zones under READY path spark.

## Driving it with the harness
`testReadinessLoadSimulatorSurface` asserts SurfaceID and `saveShot("verify-simulator-path-zone-bands.png")`.

## Gotchas
Always mounts.
