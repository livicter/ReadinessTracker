# Day Detail HRV MA7 Overlay (Honest #288)

## Intent
Elevate unused `AnalyzedDataPoint.movingAverage7` on Day Detail HRV Trend —
Sleep #281 dual. Always-on LineMark + legend (no toggles).

## Surface
- History → day row → DayDetailView → 7-Day Context → HRV Trend
- A11y: `day.detail.hrv.ma7`

## Verify
- UITest: `testDayDetailHRVMA7Surface`
- Shot: `.audit/verify-day-detail-hrv-ma7.png`

## Non-goals
- No MA14/EMA yet (→ #289); no strip triad; no BAC / HK duals; no toggles
