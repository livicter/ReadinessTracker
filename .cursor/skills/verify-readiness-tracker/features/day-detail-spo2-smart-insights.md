# Day Detail SmartInsightsView on SpO2 (Honest #326)

## Intent
Mount existing `SmartInsightsView` for SpO2/bloodOxygen when
`spo2SeriesThroughDay.count >= 3` — Sleep #267 / Strain #311 dual. Thinnest
SpO2 Day Detail track entry via optional `bloodOxygen` compactMap. No new HK.

## Surface
- History → day row → DayDetailView
- Insights card for Blood Oxygen after Strain SmartInsights
- A11y: `day.detail.spo2.smartInsights`

## Verify
- UITest: `testDayDetailSpO2SmartInsightsSurface`
- Shot: `.audit/verify-day-detail-spo2-smart-insights.png`

## Non-goals
- No SpO2 WeeklyPattern / histogram yet (→ #327); no BAC / HK duals
