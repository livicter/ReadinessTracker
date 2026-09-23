# Stair Ascent Speed Tonight|Baseline (Honest #149)

## Why
1. After gait set, `stairAscentSpeed` is strongest unused sparse mobility HK (prefer over descent / 6MWT — ascent is effortful + Watch-friendly).
2. Body stack after Step Length — not sleep-stack dual; not chrome-only.

## Plumbing
- Model: `stairAscentSpeedMps: Double?`
- HK: read `.stairAscentSpeed`; discreteAverage; m/s
- Fixture: today 0.42; older 0.28…0.49; nil every 5th

## Surface
- Today body after Step Length → **Stair Ascent**
- Strong / Solid / Easy / Slow vs ≥0.45 / ≥0.35 / ≥0.25 m/s
- A11y: `body.stairAscent.card`, `body.stairAscent.baseline`, `body.stairAscent.spark`

## Verify
- `testStairAscentSpeedTonightBaselineSurface`
- `.audit/verify-stair-ascent-speed-tonight-baseline.png`
