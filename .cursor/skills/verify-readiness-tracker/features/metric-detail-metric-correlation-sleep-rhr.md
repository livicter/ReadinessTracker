# Metric Detail MetricCorrelationView Sleep↔RHR (Honest #351)

## Intent
Mount existing `MetricCorrelationView` with x: .sleep, y: .restingHR when
metric is Sleep or Resting HR and history ≥3 — Day Detail #324 parity; extends #350.
Hosts: classic + Advanced. No new HK.

## Surface
- Today → Metrics → Sleep (or Resting HR) card → MetricDetailView
- A11y: `metric.detail.metricCorrelation.sleepRhr`

## Verify
- UITest: `testMetricDetailMetricCorrelationSleepRHRSurface`
- Shot: `.audit/verify-metric-detail-metric-correlation-sleep-rhr.png`

## Non-goals
- No Trends SpO2; no BAC / HK; no RecoveryTrajectory-on-Strain; no Body Activity SI
