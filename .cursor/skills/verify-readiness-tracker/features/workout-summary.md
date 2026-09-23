# Workout Summary (Honest #108)

## Intent
WHOOP / Apple Fitness–style workout glance on Recovery & Strain. Elevates sparse `WorkoutRow` list and seeds fixture `StrainSession`s (Running 07:30–08:30 overlapping synthetic HR) so UITests leave the empty state.

## Surface
- Today → Balance / Recovery & Strain → **Workouts**
- A11y: `strain.workouts`, `strain.workout.session|duration|trimp|hr`

## Verify
- UITest: `testWorkoutSummarySurface` asserts Workouts title, Running, no empty copy; shot `.audit/verify-workouts.png`
- Fixture: today Running 60 min via `DataStore.syntheticStrainSessions` + `StrainCalculator.enrichSessions`

## Non-goals
- No new readiness score term
- No per-interval GPS / route map
