# Day Detail SpO2 MA14 + EMA always-on overlays (Honest #335)

## Intent
Complete SpO2 overlay triad — Sleep #279 / Strain #320 dual. Fields already in
`spo2OverlaySeries` from #334 (`movingAverage14`, `ema7`). Always-on MA14 + EMA
lines + legend on Blood Oxygen Trend host.

## Surface
- History → day row → DayDetailView → Blood Oxygen Trend
- MA14 + EMA lines + legend (with MA7 from #334)
- A11y: `day.detail.spo2.ma14`, `day.detail.spo2.ema`

## Verify
- UITest: `testDayDetailSpO2MA14EMASurface`
- Shot: `.audit/verify-day-detail-spo2-ma14-ema.png`

## Non-goals
- No strip triad yet; no BAC / HK duals
