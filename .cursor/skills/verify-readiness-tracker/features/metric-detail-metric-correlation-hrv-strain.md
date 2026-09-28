# Metric Detail MetricCorrelationView HRV↔Strain (Honest #353)

## Intent
Mount existing `MetricCorrelationView` with x: .hrv, y: .activeCalories when
metric is HRV and history ≥3 — Day Detail #339 parity; extends #352.
Hosts: classic + Advanced. No new HK.

## Surface
- Today → Metrics → HRV card → MetricDetailView
- A11y: `metric.detail.metricCorrelation.hrvStrain`

## Verify
- UITest: `testMetricDetailMetricCorrelationHRVStrainSurface`
- Shot: `.audit/verify-metric-detail-metric-correlation-hrv-strain.png`

## Non-goals
- No Trends SpO2; no BAC / HK; no RecoveryTrajectory-on-Strain; no Body Activity SI
