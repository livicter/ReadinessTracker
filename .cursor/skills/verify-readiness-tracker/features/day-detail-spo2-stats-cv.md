# Day Detail SpO2 Statistics CV% (Honest #331)

## Intent
Elevate `TrendAnalysisEngine.coefficientOfVariation` on SpO2 series —
Sleep #275 / Strain #316 dual. Stats card mirrors Strain Statistics.

## Surface
- History → day row → DayDetailView
- SpO2 Statistics card with Volatility CV%
- A11y: `day.detail.spo2.stats.cv`

## Verify
- UITest: `testDayDetailSpO2StatsCVSurface`
- Shot: `.audit/verify-day-detail-spo2-stats-cv.png`

## Non-goals
- No Outlier yet (→ #332); no BAC / HK duals
