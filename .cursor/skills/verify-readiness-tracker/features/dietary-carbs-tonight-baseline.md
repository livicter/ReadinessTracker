# Carbohydrates Tonight|Baseline (Honest #173)

## Why
1. Prefer `dietaryCarbohydrates` — next unused dietary leftover after energy.
2. Completes macros cluster with protein/energy without sleep-stack duals.
3. After Dietary Energy — not chrome-only.

## Plumbing
- Model: `NutritionSummary.carbohydrateGrams: Double?`
- HK: read `.dietaryCarbohydrates`; cumulativeSum gram
- Fixture: today 210; older 120…320; nil every 5th

## Surface
- Today Body after Dietary Energy → **Carbohydrates**
- Soft 225 g goal — Goal met / On track / Building / Low
- A11y: `body.carbs.card`, `body.carbs.baseline`, `body.carbs.spark`

## Verify
- `testDietaryCarbsTonightBaselineSurface`
- `.audit/verify-dietary-carbs-tonight-baseline.png`
