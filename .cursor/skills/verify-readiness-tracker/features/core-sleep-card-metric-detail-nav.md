# Core Sleep card → MetricDetail nav (Honest #372)

## Intent
WHOOP `sleep.core.card` was display-only. Wire to classic `MetricDetailView(.sleep)`
(total asleep hours) for SpO2/RHR/Active Calories/Sleep HRV hosting parity.
Chart/spark `allowsHitTesting(false)`. SurfaceID `sleep.core.card` / `metric.detail`.

## Verify
- UITest: `testCoreSleepCardMetricDetailNavSurface`
- Shot: `.audit/verify-core-sleep-metric-detail.png`
