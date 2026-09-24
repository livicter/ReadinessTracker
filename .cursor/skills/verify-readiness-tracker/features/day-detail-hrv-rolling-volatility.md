# Day Detail HRV rollingVolatility Strip (Honest #291)

## Intent
Elevate unused `AnalyzedDataPoint.volatility` on HRV through day —
Sleep #276 dual / start of HRV strip triad. Toggle chip + Low/Mild/High
band chart via `hrvAnalyzedThroughDay`.

## Surface
- History → day row → DayDetailView
- HRV Volatility toggle + 7-Day HRV Volatility strip after Sleep strips
- A11y: `day.detail.hrv.volatility`, `day.detail.hrv.volatility.toggle`

## Verify
- UITest: `testDayDetailHRVRollingVolatilitySurface`
- Shot: `.audit/verify-day-detail-hrv-rolling-volatility.png`

## Non-goals
- No HRV momentum / Day Δ yet (→ #292+); no BAC / HK duals
