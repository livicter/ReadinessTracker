# Day Detail RHR Baseline Bands ±2σ (Honest #302)

## Intent
Mount ±2σ baseline bands + baseline rule on Day Detail Resting HR Trend
(7-Day Context), with Baseline ±2σ legend — Sleep #273 / HRV #287 dual.
Stats from `rhrSeriesThroughDay` (≥5, stdDev > 0). Always-on (no toggle).

## Surface
- History → day row → DayDetailView → 7-Day Context → Resting HR Trend
- A11y: `day.detail.rhr.baselineBands`

## Verify
- UITest: `testDayDetailRHRBaselineBandsSurface`
- Shot: `.audit/verify-day-detail-rhr-baseline-bands.png`

## Non-goals
- No MA overlays / strip triad yet; no BAC / HK duals
