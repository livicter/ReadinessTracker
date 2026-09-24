# Day Detail SmartInsightsView on HRV (Honest #290)

## Intent
Mount existing `SmartInsightsView` on `DayDetailView` for HRV series when
`hrvSeriesThroughDay.count >= 3` — Sleep #267 dual. Reuses shared insight
logic; no rewrite.

## Surface
- History → day row → DayDetailView
- Insights card for HRV after Sleep SmartInsights
- A11y: `day.detail.hrv.smartInsights`

## Verify
- UITest: `testDayDetailHRVSmartInsightsSurface`
- Shot: `.audit/verify-day-detail-hrv-smart-insights.png`

## Non-goals
- No HRV strip triad; no BAC / HK duals
