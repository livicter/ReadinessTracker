# Cycling Cadence Tonight|Baseline (Honest #154)

## Why
1. Prefer `cyclingCadence` after swim pair — strongest unused everyday activity HK vs niche `underwaterDepth`.
2. Body/activity stack after Swim Strokes — not sleep-stack dual; not chrome-only.

## Plumbing
- Model: `cyclingCadenceRpm: Double?`
- HK: read `.cyclingCadence`; discreteAverage; count/min
- Fixture: today 88; older 65…104; nil every 5th

## Surface
- Today body after Swim Strokes → **Cycling Cadence**
- High / Solid / Easy / Low vs ≥90 / ≥75 / ≥60 rpm
- A11y: `body.cyclingCadence.card`, `body.cyclingCadence.baseline`, `body.cyclingCadence.spark`

## Verify
- `testCyclingCadenceTonightBaselineSurface`
- `.audit/verify-cycling-cadence-tonight-baseline.png`
