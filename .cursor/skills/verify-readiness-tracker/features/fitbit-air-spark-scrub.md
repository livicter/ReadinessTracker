# Fitbit Air spark scrub (Honest #507)

## Sub-features
- Day scrub chips + drag on spark chart
- Callout with date + value (defaults to latest day)
- SurfaceID `fitbit.air.spark.scrub`

## How to get to it (user POV)
Today → Fitbit/Health Air → spark → day chips or drag chart.

## Driving it with the harness
- `testFitbitAirDataCardSurface` (scrub asserted before #506 re-anchor)
- `.audit/verify-fitbit-air-data-spark-scrub.png`

## Gotchas
- Default callout seeds latest day so SurfaceID is present without drag
- UITest DragGesture on Chart overlay is flaky; prefer day chips / default seed
