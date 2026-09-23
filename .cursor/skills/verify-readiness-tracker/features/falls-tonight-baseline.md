# Falls Tonight|Baseline (Honest #170)

## Why
1. Prefer `numberOfTimesFallen` — wireable cumulative falls count for Today mobility safety.
2. Completes PPI / steadiness safety cluster without sleep-stack duals.
3. After Perfusion Index — not chrome-only.

## Plumbing
- Model: `numberOfTimesFallen: Double?`
- HK: read `.numberOfTimesFallen`; cumulativeSum count
- Fixture: today 0; older 0…3; nil every 5th

## Surface
- Today body after Perfusion Index → **Falls**
- None / One / Few / Many vs ≤0 / ≤1 / ≤2
- A11y: `body.falls.card`, `body.falls.baseline`, `body.falls.spark`

## Verify
- `testFallsTonightBaselineSurface`
- `.audit/verify-falls-tonight-baseline.png`
