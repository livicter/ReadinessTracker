# Walking Speed Tonight|Baseline (Honest #147)

## Why
1. Last of the gait trio after double support + asymmetry — prefer `walkingSpeed` over `walkingStepLength` (clearer readiness/mobility signal).
2. Body stack — not sleep-stack dual; not chrome-only.

## Plumbing
- Model: `walkingSpeedMps: Double?` (meters/second)
- HK: read `.walkingSpeed`; discreteAverage; unit m/s
- Fixture: today 1.28; older 0.95…1.44; nil every 5th

## Surface
- Today body after Walking Asymmetry → **Walking Speed**
- Brisk / Steady / Easy / Slow vs ≥1.3 / ≥1.1 / ≥0.9 m/s
- A11y: `body.walkingSpeed.card`, `body.walkingSpeed.baseline`, `body.walkingSpeed.spark`

## Verify
- `testWalkingSpeedTonightBaselineSurface`
- `.audit/verify-walking-speed-tonight-baseline.png`
