# Fitbit Air density entropy

## Sub-features
- 5-bin dens hist + Shannon H
- SurfaceID `fitbit.air.density.entropy`

## How to get to it (user POV)
Today → Fitbit/Health Air → Density entropy under ACF.

## Driving it with the harness
`testFitbitAirDataCardSurface` asserts SurfaceID and `saveShot("verify-fitbit-air-density-entropy.png")`.

## Gotchas
Needs ≥5 history days.
