# Fitbit Air density forecast residual spark

## Sub-features
- Actual vs predicted density lines
- MAE capsule
- SurfaceID `fitbit.air.density.forecast.residual`

## How to get to it (user POV)
Today → Fitbit/Health Air → expand Tomorrow density → Residual chart.

## Driving it with the harness
`testFitbitAirDataCardSurface` asserts residual SurfaceID and `saveShot("verify-fitbit-air-density-forecast-residual.png")`.

## Gotchas
Needs ≥4 history days; lives inside expanded forecast detail.
