# Day Detail RHR MA14 + EMA Overlays (Honest #304)

## Intent
Elevate unused `AnalyzedDataPoint.movingAverage14` + `ema7` on Day Detail
Resting HR Trend — Sleep #279 / HRV #289 dual. Always-on LineMarks + legend.
Completes RHR overlay triad with #303 MA7.

## Surface
- History → day row → DayDetailView → 7-Day Context → Resting HR Trend
- A11y: `day.detail.rhr.ma14`, `day.detail.rhr.ema`

## Verify
- UITest: `testDayDetailRHRMA14EMASurface`
- Shot: `.audit/verify-day-detail-rhr-ma14-ema.png`

## Non-goals
- No MA toggles; no strip triad yet; no BAC / HK duals
