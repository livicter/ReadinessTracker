# Health Air density category overlays

## Sub-features
- Toggle chips Sleep / Vitals / Move
- Multi-series density chart synced to Health scrub
- Scrub callout wells per visible category
- SurfaceID `health.air.density.cats`

## How to get to it (user POV)
Today → Apple Watch source → Health Air card → Health density → Category density

## Driving it with the harness
UITest switches to Apple Watch, scrolls to health.air.density.cats, toggles Move, saves PNG.

## Gotchas
Only mounts when `source == .appleWatch` inside healthAirDensityGlance. Needs ≥2 history days.
