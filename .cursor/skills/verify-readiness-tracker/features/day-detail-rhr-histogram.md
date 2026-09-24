# Day Detail DistributionHistogramView on RHR (Honest #297)

## Intent
Mount existing `DistributionHistogramView` on `DayDetailView` for Resting HR
when `rhrSeriesThroughDay.count >= 5` — Sleep #271 / HRV #282 dual. Reuses
shared histogram; no rewrite.

## Surface
- History → day row → DayDetailView
- Distribution card for RHR after HRV histogram
- A11y: `day.detail.rhr.histogram`

## Verify
- UITest: `testDayDetailRHRHistogramSurface`
- Shot: `.audit/verify-day-detail-rhr-histogram.png`

## Non-goals
- No classifyTrend / OutlierCallout yet (→ #298+); no BAC / HK duals
