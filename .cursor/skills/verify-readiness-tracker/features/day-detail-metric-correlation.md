# Day Detail MetricCorrelationView (Honest #270)

## Intent
Mount shared `MetricCorrelationView` (Pearson) on `DayDetailView` for
Sleep↔HRV when history through the day has ≥3 points — classic Metric Detail /
Trends #266 parity. Elevates unused shared pearsonCorrelation presentation.

## Surface
- History → day row → DayDetailView
- Correlation card after Post-Strain Recovery
- `historyThroughDay` + x=.sleep, y=.hrv
- A11y: `day.detail.metricCorrelation`

## Verify
- UITest: `testDayDetailMetricCorrelationSurface`
- Shot: `.audit/verify-day-detail-metric-correlation.png`

## Non-goals
- No DistributionHistogramView / OutlierCallout yet (→ #271+); no BAC / HK duals
