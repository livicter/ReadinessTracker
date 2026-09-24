# Day Detail SpO2 Day Δ / rateOfChange strip (Honest #338)

## Intent
Elevate unused `AnalyzedDataPoint.rateOfChange` on SpO2 — Sleep #278 / Strain
#323 dual. Completes SpO2 strip triad. Extend #336 card with ToggleChip("SpO2
Day Δ") + bar strip (higherIsBetter Up/Down).

## Surface
- History → day row → DayDetailView → SpO2 Volatility card
- SpO2 Day Δ chip + SpO2 Day-over-Day Change strip
- A11y: `day.detail.spo2.dayDelta`, `day.detail.spo2.dayDelta.toggle`

## Verify
- UITest: `testDayDetailSpO2DayDeltaSurface`
- Shot: `.audit/verify-day-detail-spo2-day-delta.png`

## Non-goals
- No RecoveryTrajectory-on-SpO2; no BAC / HK duals
