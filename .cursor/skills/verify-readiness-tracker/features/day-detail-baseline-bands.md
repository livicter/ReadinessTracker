# Day Detail Baseline Bands ±2σ (Honest #273)

## Intent
Mount ±2σ baseline bands + baseline rule on Day Detail Sleep Trend
(7-Day Context), with Baseline ±2σ legend — classic #251 / Trends #258
presentation parity. Stats from `sleepSeriesThroughDay` (≥5, stdDev > 0).
No Baseline/MA7 toggle (bands always on; avoid chrome-only duals).

## Surface
- History → day row → DayDetailView → 7-Day Context → Sleep Trend
- A11y: `day.detail.baselineBands`

## Verify
- UITest: `testDayDetailBaselineBandsSurface`
- Shot: `.audit/verify-day-detail-baseline-bands.png`

## Non-goals
- No MA7 / MA14 / EMA toggles; no BAC / HK duals
