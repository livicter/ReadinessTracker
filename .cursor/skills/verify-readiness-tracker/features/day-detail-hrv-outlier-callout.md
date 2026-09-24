# Day Detail HRV OutlierCallout Highlights (Honest #286)

## Intent
Mount up to 3 shared `OutlierCallout`s on `DayDetailView` for HRV series
through day — Sleep #272 dual. Filters `isOutlier` on `hrvAnalyzedThroughDay`.

## Surface
- History → day row → DayDetailView
- HRV Highlights section after HRV DistributionHistogramView
- A11y: `day.detail.hrv.outlierList`

## Verify
- UITest: `testDayDetailHRVOutlierCalloutSurface`
- Shot: `.audit/verify-day-detail-hrv-outlier-callout.png`

## Non-goals
- No Baseline Bands / strip triad / MA overlays; no BAC / HK duals
