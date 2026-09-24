# Day Detail HRV % vs Baseline (Honest #284)

## Intent
Elevate unused `percentDeviation` for the selected day’s HRV — Sleep #280
dual via `hrvAnalyzedThroughDay` / `hrvDayAnalyzed`.

## Surface
- History → day row → DayDetailView
- Callout after HRV classifyTrend: `HRV · ±X.X% vs baseline`
- A11y: `day.detail.hrv.percentDeviation`

## Verify
- UITest: `testDayDetailHRVPercentDeviationSurface`
- Shot: `.audit/verify-day-detail-hrv-percent-deviation.png`

## Non-goals
- No HRV CV% / OutlierCallout / strip triad yet (→ #285+); no BAC / HK duals
