# Day Detail Strain MA14 + EMA Overlays (Honest #320)

## Intent
Always-on MA14 + EMA overlays on Day Detail Active Calories Trend —
Sleep #279 / HRV #289 / RHR #304 dual. Completes Strain overlay triad with
#319 MA7. Fields already in `strainOverlaySeries`.

## Surface
- History → day row → DayDetailView → 7-Day Context → Active Calories Trend
- A11y: `day.detail.strain.ma14`, `day.detail.strain.ema`

## Verify
- UITest: `testDayDetailStrainMA14EMASurface`
- Shot: `.audit/verify-day-detail-strain-ma14-ema.png`

## Non-goals
- No strip triad yet (→ #321+); no BAC / HK duals; no toggles
