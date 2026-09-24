# Day Detail rollingVolatility Strip (Honest #276)

## Intent
Elevate unused `AnalyzedDataPoint.volatility` / rollingVolatility on
`DayDetailView` Sleep through day — classic #248 / Trends #259 parity.
Toggle chip + Low/Mild/High band chart via `sleepAnalyzedThroughDay`.

## Surface
- History → day row → DayDetailView
- Volatility toggle + 7-Day Volatility strip after Statistics CV%
- A11y: `day.detail.volatility`, `day.detail.volatility.toggle`

## Verify
- UITest: `testDayDetailRollingVolatilitySurface`
- Shot: `.audit/verify-day-detail-rolling-volatility.png`

## Non-goals
- No momentum / Day Δ strips yet (→ #277+); no MA14/EMA; no BAC / HK duals
