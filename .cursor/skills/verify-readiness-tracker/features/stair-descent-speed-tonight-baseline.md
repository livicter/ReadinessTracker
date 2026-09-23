# Stair Descent Speed Tonight|Baseline (Honest #150)

## Why
1. Pair with #149 ascent — `stairDescentSpeed` unused sparse mobility HK (prefer over 6MWT).
2. Body stack after Stair Ascent — not sleep-stack dual; not chrome-only.

## Plumbing
- Model: `stairDescentSpeedMps: Double?`
- HK: read `.stairDescentSpeed`; discreteAverage; m/s
- Fixture: today 0.48; older 0.32…0.55; nil every 5th

## Surface
- Today body after Stair Ascent → **Stair Descent**
- Strong / Solid / Easy / Slow vs ≥0.45 / ≥0.35 / ≥0.25 m/s
- A11y: `body.stairDescent.card`, `body.stairDescent.baseline`, `body.stairDescent.spark`

## Verify
- `testStairDescentSpeedTonightBaselineSurface`
- `.audit/verify-stair-descent-speed-tonight-baseline.png`
