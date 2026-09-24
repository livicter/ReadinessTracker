# Day Detail Strain classifyTrend Strength (Honest #314)

## Intent
Elevate `TrendAnalysisEngine.analyze` + `classifyTrend` on Strain through day —
Sleep #274 / HRV #283 / RHR #298 dual. Adds `strainAnalyzedThroughDay` for
`metric: .activeCalories` and strength callout.

## Surface
- History → day row → DayDetailView
- "Strain · {strength}" callout near other trend callouts
- A11y: `day.detail.strain.trend.strength`

## Verify
- UITest: `testDayDetailStrainClassifyTrendSurface`
- Shot: `.audit/verify-day-detail-strain-classify-trend.png`

## Non-goals
- No Strain % vs baseline yet (→ #315); no BAC / HK duals
