# Metric Detail MetricCorrelationView RHR↔Strain (Honest #354)

## Intent
Mount existing `MetricCorrelationView` with x: .restingHR, y: .activeCalories when
metric is Resting HR or Active Calories and history ≥3 — Day Detail #340 parity;
completes MetricDetail↔Day Detail correl SurfaceID parity. Hosts: classic + Advanced.
No new HK.

## Surface
- Today → Metrics → Resting HR (or Active Calories) card → MetricDetailView
- A11y: `metric.detail.metricCorrelation.rhrStrain`

## Verify
- UITest: `testMetricDetailMetricCorrelationRHRStrainSurface`
- Shot: `.audit/verify-metric-detail-metric-correlation-rhr-strain.png`

## Non-goals
- No Trends SpO2; no BAC / HK; no RecoveryTrajectory-on-Strain; no Body Activity SI
