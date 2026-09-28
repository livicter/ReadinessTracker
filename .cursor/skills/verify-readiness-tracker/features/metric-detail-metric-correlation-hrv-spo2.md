# Metric Detail MetricCorrelationView HRV↔SpO2 (Honest #347)

## Intent
Mount existing `MetricCorrelationView` with x: .hrv, y: .bloodOxygen when
metric is HRV and history ≥3 — Day Detail #343 parity; extends #346 Sleep↔SpO2.
Hosts: classic MetricDetailView + AdvancedMetricDetailView. No new HK.

## Surface
- Today → Metrics → HRV card → MetricDetailView, or Breakdown → HRV → Advanced
- Correlation card after primary HRV↔Sleep / Correlations section
- A11y: `metric.detail.metricCorrelation.hrvSpo2`

## Verify
- UITest: `testMetricDetailMetricCorrelationHRVSpo2Surface`
- Shot: `.audit/verify-metric-detail-metric-correlation-hrv-spo2.png`

## Non-goals
- No Trends SpO2 toggle; no BAC / HK duals; no MetricType.steps;
  no RecoveryTrajectory-on-Strain
