# Fitbit Air density forecast residual bias

## Sub-features
- Signed mean residual needle
- Over/Under capsule
- SurfaceID `fitbit.air.density.forecast.bias`

## How to get to it (user POV)
Today → Fitbit/Health Air → expand Tomorrow density → Residual bias under Hit rate.

## Driving it with the harness
`testFitbitAirDataCardSurface` asserts bias SurfaceID and `saveShot("verify-fitbit-air-density-forecast-bias.png")`.

## Gotchas
Needs ≥4 history days; lives inside expanded forecast detail.
