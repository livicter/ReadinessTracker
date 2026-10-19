# Fitbit Air density skew meter

## Sub-features
- Pearson moment skewness needle
- Left/Sym/Right capsule
- SurfaceID `fitbit.air.density.skew`

## How to get to it (user POV)
Today → Fitbit/Health Air → Density skew under CV.

## Driving it with the harness
`testFitbitAirDataCardSurface` asserts skew SurfaceID and `saveShot("verify-fitbit-air-density-skew.png")`.

## Gotchas
Needs ≥5 history days.
