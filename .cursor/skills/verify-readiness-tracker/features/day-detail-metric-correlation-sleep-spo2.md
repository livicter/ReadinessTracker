# Day Detail MetricCorrelationView Sleep↔SpO2 (Honest #342)

## Intent
Mount existing `MetricCorrelationView` with x: .sleep, y: .bloodOxygen
when historyThroughDay ≥3 — thin dual of #325 Sleep↔Strain. Starts SpO2
correlation cluster. MetricCorrelationView already reads bloodOxygen. No new HK.

## Surface
- History → day row → DayDetailView
- Correlation card after RHR↔Strain
- A11y: `day.detail.metricCorrelation.sleepSpo2`

## Verify
- UITest: `testDayDetailMetricCorrelationSleepSpo2Surface`
- Shot: `.audit/verify-day-detail-metric-correlation-sleep-spo2.png`

## Non-goals
- No HRV↔SpO2 yet (→ #343); no RHR↔SpO2 / Strain↔SpO2; no BAC / HK duals
