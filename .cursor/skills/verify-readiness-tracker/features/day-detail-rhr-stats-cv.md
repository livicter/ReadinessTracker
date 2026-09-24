# Day Detail RHR Statistics CV% (Honest #300)

## Intent
Elevate unused `coefficientOfVariation` on `DayDetailView` for RHR through
day — Sleep #275 / HRV #285 dual.

## Surface
- History → day row → DayDetailView
- RHR Statistics card with Volatility CV% after RHR % vs baseline
- A11y: `day.detail.rhr.stats.cv`

## Verify
- UITest: `testDayDetailRHRStatsCVSurface`
- Shot: `.audit/verify-day-detail-rhr-stats-cv.png`

## Non-goals
- No OutlierCallout / strip triad; no BAC / HK duals
