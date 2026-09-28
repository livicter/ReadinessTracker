# Metric Detail MetricCorrelationView Sleep↔Strain (Honest #352)

## Intent
Mount existing `MetricCorrelationView` with x: .sleep, y: .activeCalories when
metric is Sleep and history ≥3 — Day Detail #325 parity; extends #351.
Active Calories classic primary already is Strain↔Sleep (generic tag).
Hosts: classic + Advanced. No new HK.

## Surface
- Today → Metrics → Sleep card → MetricDetailView
- A11y: `metric.detail.metricCorrelation.sleepStrain`

## Verify
- UITest: `testMetricDetailMetricCorrelationSleepStrainSurface`
- Shot: `.audit/verify-metric-detail-metric-correlation-sleep-strain.png`

## Non-goals
- No Trends SpO2; no BAC / HK; no RecoveryTrajectory-on-Strain; no Body Activity SI
