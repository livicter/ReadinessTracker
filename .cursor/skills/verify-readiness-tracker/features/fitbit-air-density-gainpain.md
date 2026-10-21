# Fitbit air density Gain/Pain

## Sub-features
- Density Gain/Pain meter (Bull/Net+/Mixed/Bleed)
- SurfaceID `fitbit.air.density.gainpain`

## How to get to it (user POV)
Today → Fitbit/Health Air → past Density Kappa → Density Gain/Pain

## Driving it with the harness
UITest asserts `fitbit.air.density.gainpain` and saves `.audit/verify-fitbit-air-density-gainpain.png`.

## Gotchas
Empty when history < 5 days.
