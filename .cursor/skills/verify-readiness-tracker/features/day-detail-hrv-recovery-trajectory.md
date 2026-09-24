# Day Detail RecoveryTrajectoryView on HRV (Honest #295)

## Intent
Mount existing `RecoveryTrajectoryView` for HRV when
`hrvSeriesThroughDay.count >= 5`, with activeCalories strain series —
Sleep #269 dual. Reuses shared trajectory logic; no rewrite.

## Surface
- History → day row → DayDetailView
- Post-Strain Recovery for HRV after Sleep RecoveryTrajectory
- A11y: `day.detail.hrv.recoveryTrajectory`

## Verify
- UITest: `testDayDetailHRVRecoveryTrajectorySurface`
- Shot: `.audit/verify-day-detail-hrv-recovery-trajectory.png`

## Non-goals
- No RHR track start; no BAC / HK duals
