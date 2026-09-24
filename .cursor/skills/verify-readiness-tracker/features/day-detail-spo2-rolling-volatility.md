# Day Detail SpO2 rollingVolatility strip (Honest #336)

## Intent
Elevate unused `AnalyzedDataPoint.volatility` on SpO2 via ToggleChip + strip —
Sleep #276 / Strain #321 dual. Optimal-colored line (SpO2 metric color). Strip
triad start.

## Surface
- History → day row → DayDetailView
- SpO2 Volatility chip + 7-Day SpO2 Volatility strip
- A11y: `day.detail.spo2.volatility`, `day.detail.spo2.volatility.toggle`

## Verify
- UITest: `testDayDetailSpO2RollingVolatilitySurface`
- Shot: `.audit/verify-day-detail-spo2-rolling-volatility.png`

## Non-goals
- No momentum / Day Δ yet (→ #337/#338); no BAC / HK duals
