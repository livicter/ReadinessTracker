# Day Detail HRV MA14 + EMA Overlays (Honest #289)

## Intent
Elevate unused `AnalyzedDataPoint.movingAverage14` + `ema7` on Day Detail
HRV Trend — Sleep #279 dual. Always-on LineMarks + legend (no toggles).
Completes HRV overlay triad with #288 MA7.

## Surface
- History → day row → DayDetailView → 7-Day Context → HRV Trend
- A11y: `day.detail.hrv.ma14`, `day.detail.hrv.ema`

## Verify
- UITest: `testDayDetailHRVMA14EMASurface`
- Shot: `.audit/verify-day-detail-hrv-ma14-ema.png`

## Non-goals
- No MA toggles; no strip triad; no BAC / HK duals
