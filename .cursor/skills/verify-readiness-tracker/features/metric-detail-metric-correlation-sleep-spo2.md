# Metric Detail MetricCorrelationView Sleep↔SpO2 (Honest #346)

## Intent
Mount existing `MetricCorrelationView` with x: .sleep, y: .bloodOxygen on classic
MetricDetailView when metric is Sleep or Blood Oxygen and filteredHistory ≥3 —
Day Detail #342 parity; expands MetricDetail SpO2 correlation beyond existing
SpO2↔HRV. No new HK.

## Surface
- Today → Metrics → Sleep card → MetricDetailView
- Correlation card after primary Sleep↔HRV
- A11y: `metric.detail.metricCorrelation.sleepSpo2`

## Verify
- UITest: `testMetricDetailMetricCorrelationSleepSpo2Surface`
- Shot: `.audit/verify-metric-detail-metric-correlation-sleep-spo2.png`

## Non-goals
- No Trends SpO2 toggle (no host); no BAC / HK duals; no MetricType.steps;
  no RecoveryTrajectory-on-Strain
