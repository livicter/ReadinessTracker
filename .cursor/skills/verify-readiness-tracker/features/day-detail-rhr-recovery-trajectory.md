# Day Detail RecoveryTrajectoryView on RHR (Honest #309)

## Intent
Mount existing `RecoveryTrajectoryView` for RHR when
`rhrSeriesThroughDay.count >= 5`, with activeCalories strain series —
Sleep #269 / HRV #295 dual. Completes RHR Day Detail track. Reuses shared
trajectory logic (`metric.higherIsBetter` false for restingHR); no rewrite.

## Surface
- History → day row → DayDetailView
- Post-Strain Recovery for RHR after HRV RecoveryTrajectory
- A11y: `day.detail.rhr.recoveryTrajectory`

## Verify
- UITest: `testDayDetailRHRRecoveryTrajectorySurface`
- Shot: `.audit/verify-day-detail-rhr-recovery-trajectory.png`

## Non-goals
- No BAC / HK duals; RHR Day Detail track complete
