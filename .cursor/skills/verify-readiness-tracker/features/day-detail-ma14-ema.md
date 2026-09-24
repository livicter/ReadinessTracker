# Day Detail MA14 + EMA Overlays (Honest #279)

## Intent
Elevate unused `AnalyzedDataPoint.movingAverage14` + `ema7` on Day Detail
Sleep Trend — classic #247 / Trends #262 presentation parity. Always-on
LineMarks + legend (no chrome toggles).

## Surface
- History → day row → DayDetailView → 7-Day Context → Sleep Trend
- A11y: `day.detail.ma14`, `day.detail.ema`

## Verify
- UITest: `testDayDetailMA14EMASurface`
- Shot: `.audit/verify-day-detail-ma14-ema.png`

## Non-goals
- No MA14/EMA toggles (chrome-only); no BAC / HK duals
