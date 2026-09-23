# Today MetricCard header wells

## Sub-features
- Metrics section MetricCard tiles (Sleep / HRV / Resting HR / Active Cals)
- Leading SF Symbol in circular tint well

## How to get to it (user POV)
1. Open Today
2. Scroll to Metrics
3. Each MetricCard title shows a circular tint well

## Driving it with the harness
- UITest: `SurfacesUITests.testMetricsSectionVisibleAfterScroll`
- Captures `.audit/verify-metrics.png`

## Gotchas
- Keep trend badge and sparkline
- Body tiles already welled in Honest #63 — this is Metrics MetricCard only
- Do not invent Fitness+ Move/Exercise/Stand rings
