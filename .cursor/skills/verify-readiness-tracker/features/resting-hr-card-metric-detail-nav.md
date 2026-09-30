# Resting HR card → MetricDetail nav (Honest #367)

## Intent
WHOOP `resting.hr.card` was display-only; Breakdown Recovery / Resting HR was the only
path into RHR detail. Wire the card to classic `MetricDetailView` for unused
presentation parity with Blood Oxygen (#358). Chart/spark `allowsHitTesting(false)`
so NavigationLink receives taps. Keep SurfaceID `resting.hr.card` / `metric.detail`.
No new HK / Google Health.

## Surface
- Today WHOOP stack → Resting Heart Rate card → MetricDetailView (title Resting HR)
- A11y: `resting.hr.card` → `metric.detail`

## Verify
- UITest: `testRestingHRCardMetricDetailNavSurface`
- Shot: `.audit/verify-resting-hr-metric-detail.png`

## Non-goals
- No Strain-host Sleep↔Strain remount; no Trends SpO2; no Secrets; no Connect
