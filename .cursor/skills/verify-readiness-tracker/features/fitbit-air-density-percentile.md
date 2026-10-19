# Fitbit Air density percentile rank

## Sub-features
- Mid-rank percentile gauge of tonight dens in last-14
- High/Mid/Low capsule
- SurfaceID `fitbit.air.density.percentile`

## How to get to it (user POV)
Today → Fitbit/Health Air → Density percentile under IQR.

## Driving it with the harness
`testFitbitAirDataCardSurface` asserts percentile SurfaceID and `saveShot("verify-fitbit-air-density-percentile.png")`.

## Gotchas
Needs ≥5 history days.
