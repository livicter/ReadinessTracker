# Day Detail RHR MA7 Overlay (Honest #303)

## Intent
Elevate unused `AnalyzedDataPoint.movingAverage7` on Day Detail Resting HR
Trend — Sleep #281 / HRV #288 dual. Always-on LineMark + legend (no toggles).

## Surface
- History → day row → DayDetailView → 7-Day Context → Resting HR Trend
- A11y: `day.detail.rhr.ma7`

## Verify
- UITest: `testDayDetailRHRMA7Surface`
- Shot: `.audit/verify-day-detail-rhr-ma7.png`

## Non-goals
- No MA14/EMA yet (→ #304); no strip triad; no BAC / HK duals; no toggles
