# Day Detail classifyTrend Strength (Honest #274)

## Intent
Elevate unused `classifyTrend` / TrendStrength + R² on `DayDetailView` for
Sleep through day — classic #253 / Trends #255 parity. Reuses
`sleepAnalyzedThroughDay` from #272/#273.

## Surface
- History → day row → DayDetailView
- Strength callout after 7-Day Context (before SmartInsights)
- A11y: `day.detail.trend.strength`

## Verify
- UITest: `testDayDetailClassifyTrendStrengthSurface`
- Shot: `.audit/verify-day-detail-classify-trend-strength.png`

## Non-goals
- No CV% / volatility strips yet (→ #275+); no MA14/EMA toggles; no BAC / HK duals
