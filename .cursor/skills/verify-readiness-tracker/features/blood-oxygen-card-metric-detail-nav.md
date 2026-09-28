# Blood Oxygen card → MetricDetail nav (Honest #358)

## Intent
WHOOP `blood.oxygen.card` was display-only; Breakdown SpO2 was the only path
into SpO2 detail (AdvancedMetricDetail). Wire the card to classic
`MetricDetailView` for unused presentation parity. Chart/spark
`allowsHitTesting(false)` so NavigationLink receives taps. Keep SurfaceIDs
`blood.oxygen.card` / `metric.detail`. No new HK.

## Surface
- Today WHOOP stack → Blood Oxygen card → MetricDetailView
- Recovery & Strain detail → Blood Oxygen card → MetricDetailView
- A11y: `blood.oxygen.card` → `metric.detail`

## Verify
- UITest: `testBloodOxygenCardMetricDetailNavSurface`
- Shot: `.audit/verify-blood-oxygen-metric-detail.png`
- Documents: `verify-blood-oxygen-metric-detail-358.png`

## Non-goals
- No Trends SpO2; no BAC / HK; no RecoveryTrajectory-on-Strain; no Body Activity SI
