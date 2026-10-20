# Fitbit Air density z-score strip

## Sub-features
- Tonight dens z vs last-14 μ/σ with ±3σ rail
- SurfaceID `fitbit.air.density.zscore`

## How to get to it (user POV)
Today → Fitbit/Health Air → Density z-score under slope.

## Driving it with the harness
`testFitbitAirDataCardSurface` asserts SurfaceID and `saveShot("verify-fitbit-air-density-zscore.png")`.

## Gotchas
Hidden when history < 5 days.
