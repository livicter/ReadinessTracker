# Day Detail MetricCorrelationView Strain↔SpO2 (Honest #345)

## Intent
Mount existing `MetricCorrelationView` with x: .activeCalories, y: .bloodOxygen
when historyThroughDay ≥3 — thin dual of #344 RHR↔SpO2. Completes SpO2
correlation cluster (Sleep/HRV/RHR/Strain ↔ SpO2). No new HK.

## Surface
- History → day row → DayDetailView
- Correlation card after RHR↔SpO2
- A11y: `day.detail.metricCorrelation.strainSpo2`

## Verify
- UITest: `testDayDetailMetricCorrelationStrainSpo2Surface`
- Shot: `.audit/verify-day-detail-metric-correlation-strain-spo2.png`

## Non-goals
- No RecoveryTrajectory-on-Strain (deferred); no BAC / HK duals; no MetricType.steps
