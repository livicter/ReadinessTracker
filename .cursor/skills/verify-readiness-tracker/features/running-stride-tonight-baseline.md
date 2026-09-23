# Running Stride Tonight|Baseline (Honest #162)

## Why
1. Prefer `runningStrideLength` over `runningVerticalOscillation` — pairs with GCT + running speed for run economy/form.
2. Body/activity after Ground Contact — not sleep-stack dual; not chrome-only.

## Plumbing
- Model: `runningStrideLengthMeters: Double?`
- HK: read `.runningStrideLength`; discreteAverage meters; iOS 16+
- Fixture: today 1.12; older 0.95…1.34; nil every 5th

## Surface
- Today body after Ground Contact → **Run Stride**
- Long / Solid / Short / Limited vs ≥1.20 / ≥1.05 / ≥0.90 m
- A11y: `body.runningStride.card`, `body.runningStride.baseline`, `body.runningStride.spark`

## Verify
- `testRunningStrideTonightBaselineSurface`
- `.audit/verify-running-stride-tonight-baseline.png`
