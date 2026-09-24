# Day Detail HRV Statistics CV% (Honest #285)

## Intent
Elevate unused `coefficientOfVariation` on `DayDetailView` for HRV through
day — Sleep #275 dual (classic #254 / Trends #256 Volatility CV% parity).

## Surface
- History → day row → DayDetailView
- HRV Statistics card with Volatility CV% after HRV % vs baseline callout
- A11y: `day.detail.hrv.stats.cv`

## Verify
- UITest: `testDayDetailHRVStatsCVSurface`
- Shot: `.audit/verify-day-detail-hrv-stats-cv.png`

## Non-goals
- No OutlierCallout / strip triad / BAC / HK duals; Sleep CV unchanged
