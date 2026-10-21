# Health Air density Today glance

## Sub-features
- Interactive 14d density scrub (Apple Health pink)
- Gain/Pain wells + Σ Gain / Σ Pain / Ratio
- SurfaceIDs `health.air.density.glance|scrub|gainpain`

## How to get to it (user POV)
Today → source Apple Watch → Health Air card → Health density section

## Driving it with the harness
UITest switches to Apple Watch if needed, asserts health.air.density.*, saves PNGs.

## Gotchas
Only mounts when `source == .appleWatch`. Needs ≥5 history days for Gain/Pain wells.
