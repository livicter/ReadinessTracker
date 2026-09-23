# Dietary Fat Tonight|Baseline (Honest #174)

## Why
1. Prefer `dietaryFatTotal` — next unused dietary leftover after carbs.
2. Completes macros with protein/carbs/energy without sleep-stack duals.
3. After Carbohydrates — not chrome-only.

## Plumbing
- Model: `NutritionSummary.fatGrams: Double?`
- HK: read `.dietaryFatTotal`; cumulativeSum gram
- Fixture: today 68; older 35…95; nil every 5th

## Surface
- Today Body after Carbohydrates → **Dietary Fat**
- Soft 70 g goal — Goal met / On track / Building / Low
- A11y: `body.fat.card`, `body.fat.baseline`, `body.fat.spark`

## Verify
- `testDietaryFatTonightBaselineSurface`
- `.audit/verify-dietary-fat-tonight-baseline.png`
