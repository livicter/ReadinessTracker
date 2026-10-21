# Fitbit air density detail category overlays

## Sub-features
- Sleep / Vitals / Move density lines on detail sheet
- Toggle chips + scrub callouts
- SurfaceID `fitbit.air.density.detail.cats`

## How to get to it (user POV)
Today → Fitbit/Health Air → Detail → Category density

## Driving it with the harness
UITest opens detail sheet, asserts `fitbit.air.density.detail.cats`, saves PNG.

## Gotchas
Needs ≥2 history days. At least one category must stay visible.
