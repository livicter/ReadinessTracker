# Day Detail MetricCorrelationView HRV↔SpO2 (Honest #343)

## Intent
Mount existing `MetricCorrelationView` with x: .hrv, y: .bloodOxygen
when historyThroughDay ≥3 — thin dual of #342 Sleep↔SpO2. Continues SpO2
correlation cluster. No new HK.

## Surface
- History → day row → DayDetailView
- Correlation card after Sleep↔SpO2
- A11y: `day.detail.metricCorrelation.hrvSpo2`

## Verify
- UITest: `testDayDetailMetricCorrelationHRVSpo2Surface`
- Shot: `.audit/verify-day-detail-metric-correlation-hrv-spo2.png`

## Non-goals
- No RHR↔SpO2 yet (→ #344); no Strain↔SpO2 (→ #345); no BAC / HK duals
