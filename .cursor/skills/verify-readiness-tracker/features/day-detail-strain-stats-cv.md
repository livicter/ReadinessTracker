# Day Detail Strain Statistics CV% (Honest #316)

## Intent
Elevate `TrendAnalysisEngine.coefficientOfVariation` on Strain through day —
Sleep #275 / HRV #285 / RHR #300 dual. Stats card dual of RHR
`dayDetailRHRStatsCVSection` via `strainSeriesThroughDay`.

## Surface
- History → day row → DayDetailView
- "Strain Statistics" / Volatility CV tile
- A11y: `day.detail.strain.stats.cv`

## Verify
- UITest: `testDayDetailStrainStatsCVSurface`
- Shot: `.audit/verify-day-detail-strain-stats-cv.png`

## Non-goals
- No Strain OutlierCallout yet (→ #317); no BAC / HK duals
