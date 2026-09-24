# Day Detail RHR Momentum Strip (Honest #306)

## Intent
Elevate unused `AnalyzedDataPoint.momentum` on RHR through day — Sleep #277
/ HRV #292 dual. Toggle + Rising/Falling/Flat band chart via
`rhrAnalyzedThroughDay` on the RHR strips card (alongside #305 Volatility).
RHR is lowerIsBetter: Falling = optimal, Rising = warning. Strain line color.

## Surface
- History → day row → DayDetailView
- RHR Momentum toggle beside RHR Volatility; 7-Day RHR Momentum strip
- A11y: `day.detail.rhr.momentum`, `day.detail.rhr.momentum.toggle`

## Verify
- UITest: `testDayDetailRHRMomentumSurface`
- Shot: `.audit/verify-day-detail-rhr-momentum.png`

## Non-goals
- No RHR Day Δ yet (→ #307); no BAC / HK duals
