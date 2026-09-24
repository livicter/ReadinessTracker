# Day Detail RHR OutlierCallout Highlights (Honest #301)

## Intent
Mount up to 3 shared `OutlierCallout`s on `DayDetailView` for RHR series
through day — Sleep #272 / HRV #286 dual. Filters `isOutlier` on
`rhrAnalyzedThroughDay`.

## Surface
- History → day row → DayDetailView
- RHR Highlights section after HRV Highlights
- A11y: `day.detail.rhr.outlierList`

## Verify
- UITest: `testDayDetailRHROutlierCalloutSurface`
- Shot: `.audit/verify-day-detail-rhr-outlier-callout.png`

## Non-goals
- No baseline bands / strip triad; no BAC / HK duals
