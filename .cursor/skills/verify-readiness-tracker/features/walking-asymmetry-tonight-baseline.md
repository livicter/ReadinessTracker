# Walking Asymmetry Tonight|Baseline (Honest #146)

## Why
1. After double support, `walkingAsymmetryPercentage` is strongest remaining unused gait-quality HK (prefer over speed/stepLength).
2. Body stack — not sleep-stack dual; not chrome-only.

## Plumbing
- Model: `walkingAsymmetryPercent: Double?` (0…100; lower = more symmetric)
- HK: read `.walkingAsymmetryPercentage`; discreteAverage; fraction→percent
- Fixture: today 2.4; older 1.0…6.5; nil every 5th

## Surface
- Today body after Double Support → **Walking Asymmetry**
- Symmetric / Mild / Elevated / High vs ≤3 / ≤8 / ≤15
- A11y: `body.asymmetry.card`, `body.asymmetry.baseline`, `body.asymmetry.spark`

## Verify
- `testWalkingAsymmetryTonightBaselineSurface`
- `.audit/verify-walking-asymmetry-tonight-baseline.png`
