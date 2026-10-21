# Fitbit air density detail sheet

## Sub-features
- Detail open capsule on Fitbit/Health Air header
- Sheet with 7/14/30d density scrub (Google Health style)
- Richer Gain/Pain wells (day Δ + Σ Gain/Pain/Ratio)
- SurfaceIDs `fitbit.air.density.detail*`

## How to get to it (user POV)
Today → Fitbit/Health Air header → Detail

## Driving it with the harness
UITest taps `fitbit.air.density.detail.open`, asserts sheet + scrub + wells, saves PNGs.

## Gotchas
Wells empty when history < 5 days. Dismiss via Done.
