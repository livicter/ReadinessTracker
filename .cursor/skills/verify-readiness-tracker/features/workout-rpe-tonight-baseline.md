# Workout RPE Tonight|Baseline (Honest #127)

## Intent
Elevate evening check-in `UserMetadata.workoutRPE` (1–10) into a WHOOP-style
**Tonight | Baseline** dual near Check-in Insights. Subjective session hard-ness
complements Daily TRIMP (objective). CheckInStatusCard Morning/Evening Done wells
stay chrome-only — not re-chromed.

## Surface
- Today → after Check-in Insights, before Journal Impact
- Tonight RPE vs 7-day workout-day baseline; Easy / Moderate / Hard / Very hard / Rest
- A11y: `checkin.rpe.card`, `checkin.rpe.baseline`, `checkin.rpe.spark`

## Verify
- UITest: `testWorkoutRPETonightBaselineSurface`
- Shot: `.audit/verify-workout-rpe-tonight-baseline.png`
- Fixture: `MetadataStore.seedUIFixtureCheckIns` evenings (today RPE 7 Strength; older 4…9 + rest)

## Non-goals
- No re-chrome of CheckInStatusCard wells
- No sleep-stack dual clones
