# Day Detail Day Δ / rateOfChange Strip (Honest #278)

## Intent
Elevate unused `AnalyzedDataPoint.rateOfChange` on `DayDetailView` Sleep —
completes classic #248 strip triad / Trends #261 parity (Vol #276, Mom #277,
ROC #278). Toggle + Up/Flat/Down bar strip via `sleepAnalyzedThroughDay`.

## Surface
- History → day row → DayDetailView
- Day Δ toggle beside Volatility/Momentum; Day-over-Day Change strip
- A11y: `day.detail.dayDelta`, `day.detail.dayDelta.toggle`

## Verify
- UITest: `testDayDetailDayDeltaSurface`
- Shot: `.audit/verify-day-detail-day-delta.png`

## Non-goals
- No MA14/EMA toggles; no BAC / HK duals
