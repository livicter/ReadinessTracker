# Day Detail Strain Baseline Bands ±2σ (Honest #318)

## Intent
Mount ±2σ baseline bands + baseline rule on Day Detail Active Calories Trend
(7-Day Context host chart), with Baseline ±2σ legend — Sleep #273 / HRV #287 /
RHR #302 dual. Stats from `strainSeriesThroughDay` (≥5, stdDev > 0). Always-on.

## Surface
- History → day row → DayDetailView → 7-Day Context → Active Calories Trend
- A11y: `day.detail.strain.baselineBands`

## Verify
- UITest: `testDayDetailStrainBaselineBandsSurface`
- Shot: `.audit/verify-day-detail-strain-baseline-bands.png`

## Non-goals
- No MA overlays yet (→ #319); no BAC / HK duals; no toggles
