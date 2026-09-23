# Vitamin E Tonight|Baseline (Honest #203)

## Why
1. Prefer `dietaryVitaminE` — clear leftover vitamin after vitamin A.
2. Higher-is-better soft ~15 mg RDA-style goal.
3. After Vitamin A — avoids sleep-stack / SpO2-RR / skinTemp re-chrome.

## Plumbing
- NutritionSummary: `vitaminEMg: Double?`
- HK: read `.dietaryVitaminE`; cumulativeSum milligrams
- Fixture: today 14; older 6…22; nil every 5th

## Surface
- Today body after Vitamin A → **Vitamin E**
- Met / Building / Low / Very low vs soft 15 mg
- A11y: `body.vitamine.card`, `body.vitamine.baseline`, `body.vitamine.spark`

## Verify
- `testDietaryVitaminETonightBaselineSurface`
- `.audit/verify-dietary-vitamin-e-tonight-baseline.png`
