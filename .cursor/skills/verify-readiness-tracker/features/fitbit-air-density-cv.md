# Fitbit Air density CV meter

## Sub-features
- σ/μ capsule Stable/Mixed/Volatile
- Gradient meter
- SurfaceID `fitbit.air.density.cv`

## How to get to it (user POV)
Today → Fitbit/Health Air → Density CV under hist.

## Driving it with the harness
`testFitbitAirDataCardSurface` asserts cv SurfaceID and `saveShot("verify-fitbit-air-density-cv.png")`.

## Gotchas
Needs ≥5 history days.
