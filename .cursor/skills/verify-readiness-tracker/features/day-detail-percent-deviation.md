# Day Detail % vs Baseline (Honest #280)

## Intent
Elevate unused `AnalyzedDataPoint.percentDeviation` for the selected day’s
Sleep — classic/Trends scrub-enrichment parity without scrub chrome.

## Surface
- History → day row → DayDetailView → Sleep Analysis card
- Callout under night header metrics: `±X.X% vs baseline`
- A11y: `day.detail.percentDeviation`

## Verify
- UITest: `testDayDetailPercentDeviationSurface`
- Shot: `.audit/verify-day-detail-percent-deviation.png`

## Non-goals
- No MA7 overlay / HRV dual yet (→ #281+); no BAC / HK duals
