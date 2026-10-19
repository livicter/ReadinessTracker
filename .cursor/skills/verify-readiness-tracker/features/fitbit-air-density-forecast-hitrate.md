# Fitbit Air density forecast hit-rate

## Sub-features
- Hits / total · percent capsule
- Gradient fill meter
- SurfaceID `fitbit.air.density.forecast.hitrate`

## How to get to it (user POV)
Today → Fitbit/Health Air → expand Tomorrow density → Hit rate under Residual.

## Driving it with the harness
`testFitbitAirDataCardSurface` asserts hitrate SurfaceID and `saveShot("verify-fitbit-air-density-forecast-hitrate.png")`.

## Gotchas
Needs ≥4 history days; lives inside expanded forecast detail after residual.
