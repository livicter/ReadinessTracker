# Metric Detail MetricCorrelationView Strain↔SpO2 (Honest #349)

## Intent
Mount existing `MetricCorrelationView` with x: .activeCalories, y: .bloodOxygen when
metric is Active Calories (Strain) and history ≥3 — Day Detail #345 parity; completes
MetricDetail SpO2 correlation cluster with Day Detail. Hosts: classic + Advanced.
No new HK.

## Surface
- Today → Metrics → Active Calories card → MetricDetailView, or Breakdown → Strain/Active Calories → Advanced
- Correlation card after primary Strain pair / Correlations section
- A11y: `metric.detail.metricCorrelation.strainSpo2`

## Verify
- UITest: `testMetricDetailMetricCorrelationStrainSpo2Surface`
- Shot: `.audit/verify-metric-detail-metric-correlation-strain-spo2.png`

## Non-goals
- No Trends SpO2 toggle (MetricToggle has no SpO2); no BAC / HK duals;
  no RecoveryTrajectory-on-Strain; no Body Activity SI
