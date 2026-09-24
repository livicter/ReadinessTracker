# Day Detail RecoveryTrajectoryView on SpO2 (Honest #341)

## Intent
Mount existing `RecoveryTrajectoryView` for SpO2 when
`spo2SeriesThroughDay.count >= 5` with `strainSeriesThroughDay` — Sleep #269 /
RHR #309 dual. Completes SpO2 Day Detail track (deferred RecoveryTrajectory).
No new HK.

## Surface
- History → day row → DayDetailView
- Post-Strain Recovery card for Blood Oxygen after RHR RecoveryTrajectory
- A11y: `day.detail.spo2.recoveryTrajectory`

## Verify
- UITest: `testDayDetailSpO2RecoveryTrajectorySurface`
- Shot: `.audit/verify-day-detail-spo2-recovery-trajectory.png`

## Non-goals
- No Body Activity track yet; no BAC / HK duals
