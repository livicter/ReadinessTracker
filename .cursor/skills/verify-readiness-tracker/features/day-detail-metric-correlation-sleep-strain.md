# Day Detail MetricCorrelationView Sleep↔Strain (Honest #325)

## Intent
Mount fourth shared `MetricCorrelationView` (Pearson) on `DayDetailView` for
Sleep↔Strain/activeCalories when `historyThroughDay.count >= 3` — extends
#270/#310/#324. Unused-presentation parity; no rewrite.

## Surface
- History → day row → DayDetailView
- Correlation card after Sleep↔RHR
- `historyThroughDay` + x=.sleep, y=.activeCalories
- A11y: `day.detail.metricCorrelation.sleepStrain`

## Verify
- UITest: `testDayDetailMetricCorrelationSleepStrainSurface`
- Shot: `.audit/verify-day-detail-metric-correlation-sleep-strain.png`

## Non-goals
- No SpO2 track yet; no BAC / HK duals
