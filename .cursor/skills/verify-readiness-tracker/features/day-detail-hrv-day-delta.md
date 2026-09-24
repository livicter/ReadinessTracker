# Day Detail HRV Day Δ / rateOfChange Strip (Honest #293)

## Intent
Elevate unused `AnalyzedDataPoint.rateOfChange` on HRV through day —
Sleep #278 dual; completes HRV strip triad (#291 Vol, #292 Mom, #293 ROC).
Toggle + Up/Flat/Down bar strip via `hrvAnalyzedThroughDay`.

## Surface
- History → day row → DayDetailView
- HRV Day Δ toggle beside Volatility/Momentum; HRV Day-over-Day Change strip
- A11y: `day.detail.hrv.dayDelta`, `day.detail.hrv.dayDelta.toggle`

## Verify
- UITest: `testDayDetailHRVDayDeltaSurface`
- Shot: `.audit/verify-day-detail-hrv-day-delta.png`

## Non-goals
- No BAC / HK duals; triad complete
