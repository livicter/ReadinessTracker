# Alcoholic Beverages Tonight|Baseline (Honest #177)

## Why
1. Prefer `numberOfAlcoholicBeverages` — last unused dietary leftover after sugar.
2. Distinct from journal `alcoholDrinks` check-in — live HK cumulative count dual.
3. After Dietary Sugar — not chrome-only / not sleep-stack.

## Plumbing
- Model: `NutritionSummary.alcoholicBeverages: Double?`
- HK: read `.numberOfAlcoholicBeverages`; cumulativeSum count
- Fixture: today 0; older 0…3; nil every 5th

## Surface
- Today Body after Dietary Sugar → **Alcoholic Beverages**
- None / One / Few / Many vs ≤0 / ≤1 / ≤2 / ≥3
- A11y: `body.alcohol.card`, `body.alcohol.baseline`, `body.alcohol.spark`

## Verify
- `testAlcoholicBeveragesTonightBaselineSurface`
- `.audit/verify-alcoholic-beverages-tonight-baseline.png`
