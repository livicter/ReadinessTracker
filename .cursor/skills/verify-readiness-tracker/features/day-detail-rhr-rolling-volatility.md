# Day Detail RHR rollingVolatility Strip (Honest #305)

## Intent
Elevate unused `AnalyzedDataPoint.volatility` on RHR through day —
Sleep #276 / HRV #291 dual; start of RHR strip triad. Toggle chip +
Low/Mild/High band chart via `rhrAnalyzedThroughDay`. Strain-colored line.

## Surface
- History → day row → DayDetailView
- RHR Volatility toggle + 7-Day RHR Volatility strip after HRV strips
- A11y: `day.detail.rhr.volatility`, `day.detail.rhr.volatility.toggle`

## Verify
- UITest: `testDayDetailRHRRollingVolatilitySurface`
- Shot: `.audit/verify-day-detail-rhr-rolling-volatility.png`

## Non-goals
- No RHR momentum / Day Δ yet (→ #306+); no BAC / HK duals
