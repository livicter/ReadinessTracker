# Health Air density period picker

## Sub-features
- 7 / 14 / 30 day capsules
- Resets scrub index on change
- SurfaceID `health.air.density.period`

## How to get to it (user POV)
Today → Apple Watch → Health Air → Health density → period capsules

## Driving it with the harness
UITest asserts health.air.density.period, taps 7d then 14d, saves PNG.

## Gotchas
Only when `source == .appleWatch`. Default period 14.
