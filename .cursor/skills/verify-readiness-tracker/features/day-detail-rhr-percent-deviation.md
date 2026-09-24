# Day Detail RHR % vs Baseline (Honest #299)

## Intent
Elevate unused `percentDeviation` for the selected day's RHR — Sleep #280 /
HRV #284 dual via `rhrAnalyzedThroughDay` / `rhrDayAnalyzed`. Tint uses
lowerIsBetter polarity (below baseline = improving).

## Surface
- History → day row → DayDetailView
- Callout after RHR classifyTrend: `RHR · ±X.X% vs baseline`
- A11y: `day.detail.rhr.percentDeviation`

## Verify
- UITest: `testDayDetailRHRPercentDeviationSurface`
- Shot: `.audit/verify-day-detail-rhr-percent-deviation.png`

## Non-goals
- No RHR CV% / OutlierCallout yet (→ #300+); no BAC / HK duals
