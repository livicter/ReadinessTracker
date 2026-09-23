# Walking Step Length Tonight|Baseline (Honest #148)

## Why
1. Finish gait set: double support + asymmetry + speed already elevated; `walkingStepLength` was last unused.
2. Body stack after Walking Speed — not sleep-stack dual; not chrome-only.

## Plumbing
- Model: `walkingStepLengthMeters: Double?`
- HK: read `.walkingStepLength`; discreteAverage; meters
- Fixture: today 0.72; older 0.58…0.81; nil every 5th

## Surface
- Today body after Walking Speed → **Step Length**
- Long / Typical / Short / Limited vs ≥0.75 / ≥0.65 / ≥0.55 m
- A11y: `body.stepLength.card`, `body.stepLength.baseline`, `body.stepLength.spark`

## Verify
- `testWalkingStepLengthTonightBaselineSurface`
- `.audit/verify-walking-step-length-tonight-baseline.png`
