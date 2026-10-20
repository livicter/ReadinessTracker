# Fitbit Air density envelope chart

## Sub-features
- Q1–Q3 AreaMark band + dens line + median rule
- SurfaceID `fitbit.air.density.envelope`

## How to get to it (user POV)
Today → Fitbit/Health Air → Density envelope under percentile.

## Driving it with the harness
`testFitbitAirDataCardSurface` asserts envelope SurfaceID and `saveShot("verify-fitbit-air-density-envelope.png")`.

## Gotchas
Needs ≥5 history days.
