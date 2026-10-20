# Fitbit Air density MAD meter

## Sub-features
- Median absolute deviation needle
- Stable/Mild/Volatile capsule
- SurfaceID `fitbit.air.density.mad`

## How to get to it (user POV)
Today → Fitbit/Health Air → Density MAD under envelope.

## Driving it with the harness
`testFitbitAirDataCardSurface` asserts MAD SurfaceID and `saveShot("verify-fitbit-air-density-mad.png")`.

## Gotchas
Needs ≥5 history days.
