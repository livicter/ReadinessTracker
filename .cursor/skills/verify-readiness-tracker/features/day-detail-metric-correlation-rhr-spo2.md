# Day Detail MetricCorrelationView RHR↔SpO2 (Honest #344)

## Intent
Mount existing `MetricCorrelationView` with x: .restingHR, y: .bloodOxygen
when historyThroughDay ≥3 — thin dual of #343 HRV↔SpO2. Continues SpO2
correlation cluster. No new HK.

## Surface
- History → day row → DayDetailView
- Correlation card after HRV↔SpO2
- A11y: `day.detail.metricCorrelation.rhrSpo2`

## Verify
- UITest: `testDayDetailMetricCorrelationRHRSpo2Surface`
- Shot: `.audit/verify-day-detail-metric-correlation-rhr-spo2.png`

## Non-goals
- No Strain↔SpO2 yet (→ #345); no BAC / HK duals
