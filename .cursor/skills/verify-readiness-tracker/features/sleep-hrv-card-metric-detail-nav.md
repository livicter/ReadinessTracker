# Sleep HRV card → MetricDetail nav (Honest #371)

## Intent
WHOOP `sleepHRVCard` was display-only. Wire to classic `MetricDetailView(.hrv)` for
presentation parity with SpO2/RHR/Active Calories. Chart/spark/Poincaré hit-testing off.
Keep SurfaceID `sleepHRVCard` / `metric.detail`.

## Verify
- UITest: `testSleepHRVCardMetricDetailNavSurface`
- Shot: `.audit/verify-sleep-hrv-metric-detail.png`
