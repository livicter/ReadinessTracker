# Day Detail Strain Day Δ / rateOfChange Strip (Honest #323)

## Intent
Elevate unused `AnalyzedDataPoint.rateOfChange` on Strain through day —
Sleep #278 / HRV #293 / RHR #307 dual; completes Strain strip triad (#321 Vol,
#322 Mom, #323 ROC). Toggle + Up/Flat/Down bar strip via `strainAnalyzedThroughDay`.
Active Calories higherIsBetter: Up = optimal.

## Surface
- History → day row → DayDetailView
- Strain Day Δ toggle beside Volatility/Momentum; Strain Day-over-Day Change strip
- A11y: `day.detail.strain.dayDelta`, `day.detail.strain.dayDelta.toggle`

## Verify
- UITest: `testDayDetailStrainDayDeltaSurface`
- Shot: `.audit/verify-day-detail-strain-day-delta.png`

## Non-goals
- No BAC / HK duals; triad complete. Strain Day Detail track largely complete
  (defer RecoveryTrajectory-on-Strain).
