# Metric Detail MetricCorrelationView HRV↔RHR (Honest #350)

## Intent
Mount existing `MetricCorrelationView` with x: .hrv, y: .restingHR when
metric is HRV and history ≥3 — Day Detail #310 parity; first post-SpO2-cluster
MetricDetail dual (SpO2 cluster completed in #349). Hosts: classic + Advanced.
No new HK. Resting HR classic primary already shows RHR↔HRV (generic tag).

## Surface
- Today → Metrics → HRV card → MetricDetailView, or Breakdown → HRV → Advanced
- Correlation card after HRV↔Sleep / HRV↔SpO2
- A11y: `metric.detail.metricCorrelation.hrvRhr`

## Verify
- UITest: `testMetricDetailMetricCorrelationHRVRHRSurface`
- Shot: `.audit/verify-metric-detail-metric-correlation-hrv-rhr.png`

## Non-goals
- No Trends SpO2; no BAC / HK; no RecoveryTrajectory-on-Strain; no Body Activity SI
