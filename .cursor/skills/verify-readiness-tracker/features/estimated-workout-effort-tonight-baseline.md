# Estimated Workout Effort Tonight | Baseline

Honest #228. Net-new Tonight|Baseline card for HealthKit `estimatedWorkoutEffortScore` (appleEffortScore 0–10 → `estimatedWorkoutEffortScore`).

Apple-estimated sibling of workoutEffortScore. Soft glance bands only.

## Surfaces
- `body.estimatedWorkoutEffort.card`
- `body.estimatedWorkoutEffort.baseline`
- `body.estimatedWorkoutEffort.spark`

## Verify
- UITest: `testEstimatedWorkoutEffortTonightBaselineSurface`
- Screenshot: `verify-estimated-workout-effort-tonight-baseline.png`

## Soft bands
Hard ≥7 · Solid ≥5 · Easy ≥3 /10
