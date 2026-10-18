# Fitbit Air chip → MetricDetail (Honest #506)

## Sub-features
- Steps-parity NavigationLink under Fitbit/Health Air header
- Chip `metric` field routes selected chip → classic MetricDetailView
- SurfaceID `fitbit.air.chip.md.nav`

## How to get to it (user POV)
Today → scroll to Fitbit Air / Health Air → tap “Steps detail” (or selected chip detail) → MetricDetail.

## Driving it with the harness
- `testFitbitAirDataCardSurface` (extended)
- Re-anchor until Air title `isHittable` before tapping nav (off-screen `.exists` is not enough)

## Gotchas
- Spark taps can scroll the header off-screen; use `isHittable` not `exists` for re-anchor
- BP diastolic still deferred
