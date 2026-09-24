# Day Detail HRV Baseline Bands ±2σ (Honest #287)

## Intent
Mount ±2σ baseline bands + baseline rule on Day Detail HRV Trend
(7-Day Context), with Baseline ±2σ legend — Sleep #273 dual.
Stats from `hrvSeriesThroughDay` (≥5, stdDev > 0). Always-on (no toggle).

## Surface
- History → day row → DayDetailView → 7-Day Context → HRV Trend
- A11y: `day.detail.hrv.baselineBands`

## Verify
- UITest: `testDayDetailHRVBaselineBandsSurface`
- Shot: `.audit/verify-day-detail-hrv-baseline-bands.png`

## Non-goals
- No MA overlays / strip triad; no BAC / HK duals
