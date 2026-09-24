# Day Detail MetricCorrelationView HRV↔Strain (Honest #339)

## Intent
Mount existing `MetricCorrelationView` with x: .hrv, y: .activeCalories when
historyThroughDay ≥3 — extends Sleep↔HRV / HRV↔RHR / Sleep↔RHR / Sleep↔Strain
correlation cluster. Thin unused-presentation parity; no new HK.

## Surface
- History → day row → DayDetailView
- Correlation card after Sleep↔Strain
- A11y: `day.detail.metricCorrelation.hrvStrain`

## Verify
- UITest: `testDayDetailMetricCorrelationHRVStrainSurface`
- Shot: `.audit/verify-day-detail-metric-correlation-hrv-strain.png`

## Non-goals
- No RHR↔Strain yet (→ #340); no RecoveryTrajectory-on-SpO2; no BAC / HK duals
