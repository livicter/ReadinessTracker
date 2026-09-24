# Day Detail HRV classifyTrend Strength (Honest #283)

## Intent
Elevate `classifyTrend` / TrendStrength + R² on Day Detail for HRV through
day — thin dual of Sleep #274 / Trends #255. Reuses analyze on
`hrvSeriesThroughDay`.

## Surface
- History → day row → DayDetailView
- Callout after Sleep classifyTrend: `HRV · {strength}` + R²
- A11y: `day.detail.hrv.trend.strength`

## Verify
- UITest: `testDayDetailHRVClassifyTrendSurface`
- Shot: `.audit/verify-day-detail-hrv-classify-trend.png`

## Non-goals
- No HRV strip triad; no BAC / HK duals
