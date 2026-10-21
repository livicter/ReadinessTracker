# Fitbit air density Kappa

## Sub-features
- Density Kappa meter (Strong/Firm/Soft/Thin)
- SurfaceID `fitbit.air.density.kappa`

## How to get to it (user POV)
Today → Fitbit/Health Air → past Density Martin → Density Kappa

## Driving it with the harness
UITest asserts `fitbit.air.density.kappa` and saves `.audit/verify-fitbit-air-density-kappa.png`.

## Gotchas
Empty when history < 5 days.
