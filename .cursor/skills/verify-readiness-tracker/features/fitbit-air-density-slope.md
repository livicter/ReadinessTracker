# Fitbit Air density slope meter

## Sub-features
- Dens spark + dashed OLS trend
- Rising/Stable/Falling capsule (pp/wk)
- SurfaceID `fitbit.air.density.slope`

## How to get to it (user POV)
Today → Fitbit/Health Air → Density slope under Tukey fences.

## Driving it with the harness
`testFitbitAirDataCardSurface` asserts SurfaceID and `saveShot("verify-fitbit-air-density-slope.png")`.

## Gotchas
Needs ≥5 history days.
