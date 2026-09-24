# Day Detail RecoveryTrajectoryView (Honest #269)

## Intent
Mount existing `RecoveryTrajectoryView` on `DayDetailView` when Sleep
history through the day has ≥5 points, with activeCalories strain series —
Metric Detail / Trends #265 parity. Reuses component.

## Surface
- History → day row → DayDetailView
- **Post-Strain Recovery** after Weekly Pattern
- Metric: Sleep series; strain: `strainSeriesThroughDay` (activeCalories)
- A11y: `day.detail.recoveryTrajectory`

## Verify
- UITest: `testDayDetailRecoveryTrajectorySurface`
- Shot: `.audit/verify-day-detail-recovery-trajectory.png`

## Non-goals
- No classic MA7 toggle; no BAC / HK duals
