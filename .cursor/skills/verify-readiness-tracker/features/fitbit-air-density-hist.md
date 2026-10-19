# Fitbit Air density distribution histogram

## Sub-features
- Four density bins BarMark
- Mean capsule
- SurfaceID `fitbit.air.density.hist`

## How to get to it (user POV)
Today → Fitbit/Health Air → Density hist under history spark.

## Driving it with the harness
`testFitbitAirDataCardSurface` asserts hist SurfaceID and `saveShot("verify-fitbit-air-density-hist.png")`.

## Gotchas
Needs ≥5 history days.
