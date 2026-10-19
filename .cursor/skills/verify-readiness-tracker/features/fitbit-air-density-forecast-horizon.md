# Fitbit Air density forecast horizon

## Sub-features
- D+1 / D+2 / D+3 projected density bars
- Confidence taper with horizon + residual span
- SurfaceID `fitbit.air.density.forecast.horizon`

## How to get to it (user POV)
Today → Fitbit/Health Air card → expand Tomorrow density → Horizon bars.

## Driving it with the harness
`testFitbitAirDataCardSurface` expands forecast, asserts `fitbit.air.density.forecast.horizon`, `saveShot("verify-fitbit-air-density-forecast-horizon.png")`.

## Gotchas
Requires `showDensityForecastDetail` open; needs ≥4 history days for forecast.
