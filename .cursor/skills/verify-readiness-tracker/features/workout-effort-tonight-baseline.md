# Workout Effort Tonight | Baseline

Honest #227. Net-new Tonight|Baseline card for HealthKit `workoutEffortScore` (appleEffortScore 0–10 → `workoutEffortScore`).

Prefer user workoutEffortScore over estimatedWorkoutEffortScore. Soft glance bands only.

## Surfaces
- `body.workoutEffort.card`
- `body.workoutEffort.baseline`
- `body.workoutEffort.spark`

## Verify
- UITest: `testWorkoutEffortTonightBaselineSurface`
- Screenshot: `verify-workout-effort-tonight-baseline.png`

## Soft bands
Hard ≥7 · Solid ≥5 · Easy ≥3 /10
