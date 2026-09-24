# Day Detail HRV Momentum Strip (Honest #292)

## Intent
Elevate unused `AnalyzedDataPoint.momentum` on HRV through day — Sleep #277
dual. Toggle + Rising/Flat/Fading band chart via `hrvAnalyzedThroughDay` on
the HRV strips card (alongside #291 Volatility).

## Surface
- History → day row → DayDetailView
- HRV Momentum toggle beside HRV Volatility; 7-Day HRV Momentum strip
- A11y: `day.detail.hrv.momentum`, `day.detail.hrv.momentum.toggle`

## Verify
- UITest: `testDayDetailHRVMomentumSurface`
- Shot: `.audit/verify-day-detail-hrv-momentum.png`

## Non-goals
- No HRV Day Δ yet (→ #293); no BAC / HK duals
