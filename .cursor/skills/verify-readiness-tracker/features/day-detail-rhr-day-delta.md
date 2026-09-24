# Day Detail RHR Day Δ / rateOfChange Strip (Honest #307)

## Intent
Elevate unused `AnalyzedDataPoint.rateOfChange` on RHR through day —
Sleep #278 / HRV #293 dual; completes RHR strip triad (#305 Vol, #306 Mom,
#307 ROC). Toggle + Up/Flat/Down bar strip via `rhrAnalyzedThroughDay`.
RHR lowerIsBetter: Down = optimal, Up = warning.

## Surface
- History → day row → DayDetailView
- RHR Day Δ toggle beside Volatility/Momentum; RHR Day-over-Day Change strip
- A11y: `day.detail.rhr.dayDelta`, `day.detail.rhr.dayDelta.toggle`

## Verify
- UITest: `testDayDetailRHRDayDeltaSurface`
- Shot: `.audit/verify-day-detail-rhr-day-delta.png`

## Non-goals
- No BAC / HK duals; triad complete. Next: WeeklyPattern / RecoveryTrajectory.
