# Day Detail Strain % vs Baseline (Honest #315)

## Intent
Elevate unused `AnalyzedDataPoint.percentDeviation` on selected-day Strain —
Sleep #280 / HRV #284 / RHR #299 dual. Uses `strainAnalyzedThroughDay` from
#314. Active Calories is higherIsBetter: above baseline = optimal.

## Surface
- History → day row → DayDetailView
- "Strain · ±X% vs baseline" callout
- A11y: `day.detail.strain.percentDeviation`

## Verify
- UITest: `testDayDetailStrainPercentDeviationSurface`
- Shot: `.audit/verify-day-detail-strain-percent-deviation.png`

## Non-goals
- No Strain Stats CV yet (→ #316); no BAC / HK duals
