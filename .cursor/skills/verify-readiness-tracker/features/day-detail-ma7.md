# Day Detail MA7 Overlay (Honest #281)

## Intent
Elevate unused `AnalyzedDataPoint.movingAverage7` on Day Detail Sleep Trend —
completes MA7 alongside #279 MA14/EMA. Always-on LineMark + legend (no toggles).

## Surface
- History → day row → DayDetailView → 7-Day Context → Sleep Trend
- A11y: `day.detail.ma7`

## Verify
- UITest: `testDayDetailMA7Surface`
- Shot: `.audit/verify-day-detail-ma7.png`

## Non-goals
- No MA toggles; no HRV dual; no BAC / HK duals
