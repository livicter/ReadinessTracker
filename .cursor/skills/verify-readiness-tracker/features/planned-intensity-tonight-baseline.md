# Planned Intensity Tonight|Baseline (Honest #129)

## Intent
Elevate evening check-in `plannedWorkoutIntensity` (Light / Moderate / Heavy)
into a WHOOP-style **Tonight | Baseline** dual after Workout RPE. Tomorrow’s
load plan was unused on Today. CheckInStatusCard wells stay chrome-only.

## Surface
- Today → after Workout RPE, before Journal Impact
- Tonight score /3 + type caption vs 7-day planned-day average
- A11y: `checkin.plan.card`, `checkin.plan.baseline`, `checkin.plan.spark`

## Verify
- UITest: `testPlannedIntensityTonightBaselineSurface`
- Shot: `.audit/verify-planned-intensity-tonight-baseline.png`
- Fixture: evenings seed plan (today Moderate · Zones 2; older Light/Moderate/Heavy + rest)

## Non-goals
- No re-chrome of CheckInStatusCard wells
- No sleep-stack dual clones
