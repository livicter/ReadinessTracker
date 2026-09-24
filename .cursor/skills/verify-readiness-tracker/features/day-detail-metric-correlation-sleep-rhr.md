# Day Detail MetricCorrelationView Sleep↔RHR (Honest #324)

## Intent
Mount third shared `MetricCorrelationView` (Pearson) on `DayDetailView` for
Sleep↔RHR when `historyThroughDay.count >= 3` — extends #270 Sleep↔HRV and
#310 HRV↔RHR. Unused-presentation parity; no rewrite.

## Surface
- History → day row → DayDetailView
- Correlation card after HRV↔RHR correlation
- `historyThroughDay` + x=.sleep, y=.restingHR
- A11y: `day.detail.metricCorrelation.sleepRhr`

## Verify
- UITest: `testDayDetailMetricCorrelationSleepRHRSurface`
- Shot: `.audit/verify-day-detail-metric-correlation-sleep-rhr.png`

## Non-goals
- No Strain correlation cards yet; no BAC / HK duals
