# Fitbit Air density Martin

## Sub-features
- Density Martin meter (Cruising/Steady/Drag/Sink)
- SurfaceID `fitbit.air.density.martin`

## How to get to it (user POV)
Today → Fitbit/Health Air card → scroll density meters past Burke → Martin

## Driving it with the harness
UITest asserts `fitbit.air.density.martin` (fallback burke/density) and saves `.audit/verify-fitbit-air-density-martin.png`.

## Gotchas
Needs ≥5 history days. EmptyView otherwise.
