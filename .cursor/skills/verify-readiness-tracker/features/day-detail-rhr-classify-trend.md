# Day Detail RHR classifyTrend Strength (Honest #298)

## Intent
Elevate `classifyTrend` / TrendStrength + R² on Day Detail for RHR through
day — dual of Sleep #274 / HRV #283. Adds `rhrAnalyzedThroughDay`.

## Surface
- History → day row → DayDetailView
- Callout after HRV classifyTrend: `RHR · {strength}` + R²
- A11y: `day.detail.rhr.trend.strength`

## Verify
- UITest: `testDayDetailRHRClassifyTrendSurface`
- Shot: `.audit/verify-day-detail-rhr-classify-trend.png`

## Non-goals
- No RHR % vs baseline / CV% yet (→ #299+); no BAC / HK duals
