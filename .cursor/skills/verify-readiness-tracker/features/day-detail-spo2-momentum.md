# Day Detail SpO2 momentum strip (Honest #337)

## Intent
Elevate unused `AnalyzedDataPoint.momentum` on SpO2 — Sleep #277 / Strain #322
dual. Extend #336 card with ToggleChip("SpO2 Momentum") + strip (higherIsBetter
Rising/Fading; optimal line).

## Surface
- History → day row → DayDetailView → SpO2 Volatility card
- SpO2 Momentum chip + 7-Day SpO2 Momentum strip
- A11y: `day.detail.spo2.momentum`, `day.detail.spo2.momentum.toggle`

## Verify
- UITest: `testDayDetailSpO2MomentumSurface`
- Shot: `.audit/verify-day-detail-spo2-momentum.png`

## Non-goals
- No Day Δ yet (→ #338); no BAC / HK duals
