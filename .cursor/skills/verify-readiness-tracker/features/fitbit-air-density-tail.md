# Fitbit air density Tail Ratio

## Sub-features
- Density Tail Ratio meter (Fat/Balanced/Lean/Left)
- Delta histogram with left/right tail shading
- SurfaceID `fitbit.air.density.tail`

## How to get to it (user POV)
Today → Fitbit/Health Air → past Density Gain/Pain → Density Tail

## Driving it with the harness
UITest asserts `fitbit.air.density.tail` and saves `.audit/verify-fitbit-air-density-tail.png`.

## Gotchas
Empty when history < 6 days. Tail size ≈ 20% of deltas (min 1).
