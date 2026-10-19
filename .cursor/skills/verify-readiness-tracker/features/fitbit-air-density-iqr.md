# Fitbit Air density IQR band

## Sub-features
- Q1–Q3 band with median needle
- Tight/Steady/Wide capsule
- SurfaceID `fitbit.air.density.iqr`

## How to get to it (user POV)
Today → Fitbit/Health Air → Density IQR under skew.

## Driving it with the harness
`testFitbitAirDataCardSurface` asserts IQR SurfaceID and `saveShot("verify-fitbit-air-density-iqr.png")`.

## Gotchas
Needs ≥5 history days.
