# Health Air density Detail sheet

## Sub-features
- Detail capsule on Health Air card (`health.air.density.detail.open`)
- Sheet with 7/14/30d, scrub, Gain/Pain wells, category overlays
- Health pink accent; SurfaceIDs `health.air.density.detail*`

## How to get to it (user POV)
Today → Apple Watch → Health Air → Detail

## Driving it with the harness
UITest taps health.air.density.detail.open, asserts detail/scrub/gainpain/cats, saves PNGs.

## Gotchas
Only when `source == .appleWatch`. Fitbit keeps `fitbit.air.density.detail*`.
