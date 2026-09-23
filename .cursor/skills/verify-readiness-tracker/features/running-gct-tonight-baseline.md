# Running Ground Contact Tonight|Baseline (Honest #161)

## Why
1. Prefer `runningGroundContactTime` over strideLength / verticalOscillation — strongest unused run-form/fatigue HK.
2. Body/activity after Running Speed — not sleep-stack dual; not chrome-only.

## Plumbing
- Model: `runningGroundContactMs: Double?` (HK seconds × 1000)
- HK: read `.runningGroundContactTime`; discreteAverage; seconds→ms; iOS 16+
- Fixture: today 242; older 210…289; nil every 5th

## Surface
- Today body after Running Speed → **Ground Contact**
- Snappy / Solid / Heavy / Slow vs ≤220 / ≤260 / ≤300 ms
- A11y: `body.runningGCT.card`, `body.runningGCT.baseline`, `body.runningGCT.spark`

## Verify
- `testRunningGCTTonightBaselineSurface`
- `.audit/verify-running-gct-tonight-baseline.png`
