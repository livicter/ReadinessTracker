# Fitbit Air density ACF₁ meter

## Sub-features
- Lag-1 autocorrelation needle −1…+1
- Sticky/Mild/Noise/Flip capsule
- SurfaceID `fitbit.air.density.acf`

## How to get to it (user POV)
Today → Fitbit/Health Air → Density ACF₁ under z-score.

## Driving it with the harness
`testFitbitAirDataCardSurface` asserts SurfaceID and `saveShot("verify-fitbit-air-density-acf.png")`.

## Gotchas
Needs ≥6 history days.
