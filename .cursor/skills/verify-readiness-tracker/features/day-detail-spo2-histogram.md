# Day Detail DistributionHistogramView on SpO2 (Honest #328)

## Intent
Mount existing `DistributionHistogramView` for SpO2 when
`spo2SeriesThroughDay.count >= 5` — Sleep #271 / Strain #313 dual.
Reuses #326 series helper. No new HK.

## Surface
- History → day row → DayDetailView
- Distribution histogram for Blood Oxygen after Strain histogram
- A11y: `day.detail.spo2.histogram`

## Verify
- UITest: `testDayDetailSpO2HistogramSurface`
- Shot: `.audit/verify-day-detail-spo2-histogram.png`

## Non-goals
- No classifyTrend / %dev yet (→ #329); no BAC / HK duals
