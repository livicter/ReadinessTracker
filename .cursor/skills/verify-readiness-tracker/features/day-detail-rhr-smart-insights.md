# Day Detail SmartInsightsView on RHR (Honest #296)

## Intent
Mount existing `SmartInsightsView` on `DayDetailView` for Resting HR when
`rhrSeriesThroughDay.count >= 3` — thinnest start of RHR Day Detail duals.
Reuses shared insight logic; no rewrite.

## Surface
- History → day row → DayDetailView
- Insights card for RHR after HRV SmartInsights
- A11y: `day.detail.rhr.smartInsights`

## Verify
- UITest: `testDayDetailRHRSmartInsightsSurface`
- Shot: `.audit/verify-day-detail-rhr-smart-insights.png`

## Non-goals
- No Histogram / classifyTrend yet (→ #297+); no BAC / HK duals
