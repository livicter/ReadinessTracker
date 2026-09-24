# Day Detail Strain Momentum Strip (Honest #322)

## Intent
Elevate unused `AnalyzedDataPoint.momentum` on Strain through day — Sleep #277
/ HRV #292 / RHR #306 dual. Toggle + Rising/Flat/Fading band chart via
`strainAnalyzedThroughDay` on the Strain strips card (alongside #321 Volatility).
Active Calories is higherIsBetter: Rising = optimal. Caution line color.

## Surface
- History → day row → DayDetailView
- Strain Momentum toggle beside Strain Volatility; 7-Day Strain Momentum strip
- A11y: `day.detail.strain.momentum`, `day.detail.strain.momentum.toggle`

## Verify
- UITest: `testDayDetailStrainMomentumSurface`
- Shot: `.audit/verify-day-detail-strain-momentum.png`

## Non-goals
- No Strain Day Δ yet (→ #323); no BAC / HK duals
