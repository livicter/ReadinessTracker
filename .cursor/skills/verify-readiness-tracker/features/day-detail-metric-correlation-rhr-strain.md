# Day Detail MetricCorrelationView RHR↔Strain (Honest #340)

## Intent
Mount existing `MetricCorrelationView` with x: .restingHR, y: .activeCalories
when historyThroughDay ≥3 — thin dual of #339 HRV↔Strain. Completes remaining
Strain correlation pair. No new HK.

## Surface
- History → day row → DayDetailView
- Correlation card after HRV↔Strain
- A11y: `day.detail.metricCorrelation.rhrStrain`

## Verify
- UITest: `testDayDetailMetricCorrelationRHRStrainSurface`
- Shot: `.audit/verify-day-detail-metric-correlation-rhr-strain.png`

## Non-goals
- No SpO2 RecoveryTrajectory yet (→ #341); no BAC / HK duals
