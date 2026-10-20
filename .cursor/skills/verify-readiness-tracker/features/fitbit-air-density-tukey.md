# Fitbit Air density Tukey fences

## Sub-features
- Box + 1.5×IQR whiskers + outlier ticks
- SurfaceID `fitbit.air.density.tukey`

## How to get to it (user POV)
Today → Fitbit/Health Air → Density fences under MAD.

## Driving it with the harness
`testFitbitAirDataCardSurface` asserts SurfaceID and `saveShot("verify-fitbit-air-density-tukey.png")`.

## Gotchas
Hidden when history < 5 days.
