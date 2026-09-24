# Day Detail SpO2 MA7 always-on overlay (Honest #334)

## Intent
Elevate `AnalyzedDataPoint.movingAverage7` on SpO2 via `spo2OverlaySeries` —
Sleep #281 / Strain #319 dual. Always-on MA7 line + legend on Blood Oxygen Trend
host (#333). Overlay series also carries ma14/ema for #335.

## Surface
- History → day row → DayDetailView → Blood Oxygen Trend
- MA7 line + legend
- A11y: `day.detail.spo2.ma7`

## Verify
- UITest: `testDayDetailSpO2MA7Surface`
- Shot: `.audit/verify-day-detail-spo2-ma7.png`

## Non-goals
- No MA14/EMA yet (→ #335); no BAC / HK duals
