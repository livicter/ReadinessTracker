# Workout Minutes (Honest #118)

## Intent
Elevate `DailyHealthData.workoutMinutes` (feeds `StrainCalculator` duration score) into a WHOOP-style **Tonight | Baseline** dual callout on the Today Recovery & Strain stack. Metrics tiles emphasize calories/steps; WorkoutSummaryCard remains the session list on detail — not re-chromed.

## Surface
- Today → WHOOP Recovery & Strain → **Workout Minutes** (after Strain|Recovery balance, before Resting HR)
- A11y: `strain.workoutMinutes.card`, `strain.workoutMinutes.baseline`, `strain.workoutMinutes.spark`

## Verify
- UITest: `testWorkoutMinutesSurface` asserts title, Tonight, Baseline; shot `.audit/verify-workout-minutes.png`
- Fixture: today 60 min (Active); older days 15…59 so 7-day spark has shape

## Non-goals
- No changes to WorkoutSummaryCard session rows
- No new readiness score term
- strainSessions list unchanged
