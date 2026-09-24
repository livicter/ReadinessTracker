# Day Detail OutlierCallout Highlights (Honest #272)

## Intent
Mount up to 3 shared `OutlierCallout`s on `DayDetailView` for Sleep series
through day — classic #251 / Trends #257 parity. Runs
`TrendAnalysisEngine.analyze` on `sleepSeriesThroughDay`, filters `isOutlier`.

## Surface
- History → day row → DayDetailView
- Highlights section after DistributionHistogramView
- A11y: `day.detail.outlierList`

## Verify
- UITest: `testDayDetailOutlierCalloutSurface`
- Shot: `.audit/verify-day-detail-outlier-callout.png`

## Non-goals
- No Baseline Bands yet (→ #273); no BAC / HK duals; no classic MA7 toggle
