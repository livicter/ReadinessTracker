# Day Detail DistributionHistogramView (Honest #271)

## Intent
Mount shared `DistributionHistogramView` on `DayDetailView` for Sleep when
`sleepSeriesThroughDay.count >= 5` — classic Metric Detail / Trends #255
presentation parity. Elevates unused shared distribution histogram on Day Detail.

## Surface
- History → day row → DayDetailView
- Distribution card after MetricCorrelationView
- `sleepSeriesThroughDay` + metric `.sleep`
- A11y: `day.detail.histogram`

## Verify
- UITest: `testDayDetailDistributionHistogramSurface`
- Shot: `.audit/verify-day-detail-distribution-histogram.png`

## Non-goals
- No OutlierCallout yet (→ #272+); no BAC / HK duals; no classic MA7 toggle
