# Apple Exercise Time Tonight|Baseline (Honest #143)

## Why
1. `workoutMinutes` already elevated (`WorkoutMinutesCard` Tonight|Baseline).
2. `appleExerciseTime` (Activity ring exercise minutes) unused sparse HK — complementary move signal.

## Plumbing
- Model: `appleExerciseTimeMinutes: Double?`
- HK: read `.appleExerciseTime`; day cumulativeSum (minutes)
- Fixture: today 32; older 10…49; nil every 5th

## Surface
- Today strain stack after Workout Minutes → **Exercise Time**
- Met / Solid / Light / Low vs 30-min guide
- A11y: `strain.exerciseTime.card`, `strain.exerciseTime.baseline`, `strain.exerciseTime.spark`

## Verify
- `testAppleExerciseTimeTonightBaselineSurface`
- `.audit/verify-apple-exercise-time-tonight-baseline.png`
