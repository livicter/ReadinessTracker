# Day Detail Strain rollingVolatility Strip (Honest #321)

## Intent
Elevate unused `AnalyzedDataPoint.volatility` on Strain through day —
Sleep #276 / HRV #291 / RHR #305 dual; start of Strain strip triad. Toggle
chip + Low/Mild/High band chart via `strainAnalyzedThroughDay`. Caution-
colored line (activeCalories).

## Surface
- History → day row → DayDetailView
- Strain Volatility toggle + 7-Day Strain Volatility strip after RHR strips
- A11y: `day.detail.strain.volatility`, `day.detail.strain.volatility.toggle`

## Verify
- UITest: `testDayDetailStrainRollingVolatilitySurface`
- Shot: `.audit/verify-day-detail-strain-rolling-volatility.png`

## Non-goals
- No Strain momentum / Day Δ yet (→ #322+); no BAC / HK duals
