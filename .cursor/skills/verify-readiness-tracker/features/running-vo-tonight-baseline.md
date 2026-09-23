# Running Vertical Oscillation Tonight|Baseline (Honest #163)

## Why
1. Prefer `runningVerticalOscillation` — finishes run-form set with GCT + stride (bounce efficiency).
2. Body/activity after Run Stride — not sleep-stack dual; not chrome-only.

## Plumbing
- Model: `runningVerticalOscillationCm: Double?` (HK meters × 100)
- HK: read `.runningVerticalOscillation`; discreteAverage; m→cm; iOS 16+
- Fixture: today 8.4; older 6.5…11.4; nil every 5th

## Surface
- Today body after Run Stride → **Vert Oscillation**
- Efficient / Solid / Bouncey / High vs ≤7.5 / ≤9.0 / ≤11.0 cm
- A11y: `body.runningVO.card`, `body.runningVO.baseline`, `body.runningVO.spark`

## Verify
- `testRunningVOTonightBaselineSurface`
- `.audit/verify-running-vo-tonight-baseline.png`
