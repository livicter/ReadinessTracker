# Day Detail SpO2 classifyTrend strength (Honest #329)

## Intent
Elevate `TrendAnalysisEngine.analyze` + `classifyTrend` on SpO2 via
`spo2AnalyzedThroughDay` — Sleep #274 / Strain #314 dual. Callout presentation
matches Strain/RHR strength cards.

## Surface
- History → day row → DayDetailView
- SpO2 · {strength} callout near Strain classifyTrend
- A11y: `day.detail.spo2.trend.strength`

## Verify
- UITest: `testDayDetailSpO2ClassifyTrendSurface`
- Shot: `.audit/verify-day-detail-spo2-classify-trend.png`

## Non-goals
- No %dev / CV / Outlier yet; no BAC / HK duals; no RecoveryTrajectory-on-SpO2
