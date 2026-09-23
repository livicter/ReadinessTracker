# Underwater Depth Tonight|Baseline (Honest #155)

## Why
1. Prefer `underwaterDepth` after cycling cadence — unused sparse Ultra/dive HK (before cyclingPower/FTP).
2. Body/activity stack after Cycling Cadence — not sleep-stack dual; not chrome-only.

## Plumbing
- Model: `underwaterDepthMeters: Double?` (day max)
- HK: read `.underwaterDepth`; discreteMax; meters; iOS 16+
- Fixture: today 18.5; older 8…35; nil every 5th

## Surface
- Today body after Cycling Cadence → **Underwater Depth**
- Deep / Sport / Shallow / Surface vs ≥30 / ≥18 / ≥10 m
- A11y: `body.underwaterDepth.card`, `body.underwaterDepth.baseline`, `body.underwaterDepth.spark`

## Verify
- `testUnderwaterDepthTonightBaselineSurface`
- `.audit/verify-underwater-depth-tonight-baseline.png`
