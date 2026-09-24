# Day Detail Strain MA7 Overlay (Honest #319)

## Intent
Elevate unused `AnalyzedDataPoint.movingAverage7` on Day Detail Active Calories
Trend — Sleep #281 / HRV #288 / RHR #303 dual. Always-on LineMark + legend
(no toggles). Uses `strainOverlaySeries` from `strainAnalyzedThroughDay`.

## Surface
- History → day row → DayDetailView → 7-Day Context → Active Calories Trend
- A11y: `day.detail.strain.ma7`

## Verify
- UITest: `testDayDetailStrainMA7Surface`
- Shot: `.audit/verify-day-detail-strain-ma7.png`

## Non-goals
- No MA14/EMA yet (→ #320); no strip triad; no BAC / HK duals; no toggles
