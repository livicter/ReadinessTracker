# Day Detail MetricCorrelationView HRV↔RHR (Honest #310)

## Intent
Mount second shared `MetricCorrelationView` (Pearson) on `DayDetailView` for
HRV↔RHR when `historyThroughDay.count >= 3` — extends #270 Sleep↔HRV;
MetricDetail already pairs restingHR↔hrv. Unused-presentation parity; no rewrite.

## Surface
- History → day row → DayDetailView
- Correlation card after Sleep↔HRV correlation
- `historyThroughDay` + x=.hrv, y=.restingHR
- A11y: `day.detail.metricCorrelation.hrvRhr`

## Verify
- UITest: `testDayDetailMetricCorrelationHRVRHRSurface`
- Shot: `.audit/verify-day-detail-metric-correlation-hrv-rhr.png`

## Non-goals
- No Sleep↔RHR third card yet; no BAC / HK duals
