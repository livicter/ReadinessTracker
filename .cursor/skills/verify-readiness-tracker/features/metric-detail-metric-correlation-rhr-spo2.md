# Metric Detail MetricCorrelationView RHR↔SpO2 (Honest #348)

## Intent
Mount existing `MetricCorrelationView` with x: .restingHR, y: .bloodOxygen when
metric is Resting HR and history ≥3 — Day Detail #344 parity; extends #347 HRV↔SpO2.
Hosts: classic MetricDetailView + AdvancedMetricDetailView. No new HK.

## Surface
- Today → Metrics → Resting HR card → MetricDetailView, or Breakdown → Resting HR → Advanced
- Correlation card after primary RHR pair / Correlations section
- A11y: `metric.detail.metricCorrelation.rhrSpo2`

## Verify
- UITest: `testMetricDetailMetricCorrelationRHRSpo2Surface`
- Shot: `.audit/verify-metric-detail-metric-correlation-rhr-spo2.png`

## Non-goals
- No Trends SpO2 toggle; no BAC / HK duals; no MetricType.steps;
  no RecoveryTrajectory-on-Strain; no Body Activity SI
