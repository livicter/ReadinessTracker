# Inhaler Usage Tonight|Baseline (Honest #178)

## Why
1. Prefer `inhalerUsage` — first medical-sparse unused HK after dietary leftovers exhausted.
2. Cumulative puff count; respiratory-adjacent without sleep-stack duals.
3. After Alcoholic Beverages — not chrome-only.

## Plumbing
- Model: `inhalerUsage: Double?` on DailyHealthData
- HK: read `.inhalerUsage`; cumulativeSum count
- Fixture: today 0; older 0…6; nil every 5th

## Surface
- Today body after Alcoholic Beverages → **Inhaler Usage**
- None / Light / Moderate / Heavy vs ≤0 / ≤2 / ≤5 / ≥6
- A11y: `body.inhaler.card`, `body.inhaler.baseline`, `body.inhaler.spark`

## Verify
- `testInhalerUsageTonightBaselineSurface`
- `.audit/verify-inhaler-usage-tonight-baseline.png`
