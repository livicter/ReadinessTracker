# Day Detail SpO2 % vs baseline (Honest #330)

## Intent
Elevate unused `AnalyzedDataPoint.percentDeviation` on SpO2 via
`spo2DayAnalyzed` from `#329 spo2AnalyzedThroughDay` — Sleep #280 / Strain #315
dual. higherIsBetter tint (above baseline = optimal).

## Surface
- History → day row → DayDetailView
- SpO2 · ±N% vs baseline callout
- A11y: `day.detail.spo2.percentDeviation`

## Verify
- UITest: `testDayDetailSpO2PercentDeviationSurface`
- Shot: `.audit/verify-day-detail-spo2-percent-deviation.png`

## Non-goals
- No Stats CV / Outlier yet (→ #331/#332); no BAC / HK duals
