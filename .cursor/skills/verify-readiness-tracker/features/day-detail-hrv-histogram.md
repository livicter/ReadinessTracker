# Day Detail HRV DistributionHistogramView (Honest #282)

## Intent
Mount shared `DistributionHistogramView` on Day Detail for HRV through day
(≥5) — thin unused-series dual of Sleep #271 / Trends #255.

## Surface
- History → day row → DayDetailView
- After Sleep Distribution histogram
- A11y: `day.detail.hrv.histogram`

## Verify
- UITest: `testDayDetailHRVHistogramSurface`
- Shot: `.audit/verify-day-detail-hrv-histogram.png`

## Non-goals
- No HRV classifyTrend yet (→ #283); no strip triad; no BAC / HK duals
