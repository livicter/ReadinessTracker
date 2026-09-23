# Dietary Potassium Tonight|Baseline (Honest #191)

## Why
1. Prefer `dietaryPotassium` — next micronutrient leftover after sodium.
2. Higher-is-better soft ~3400 mg goal (readiness/nutrition-adjacent).
3. After Dietary Sodium — avoids sleep-stack / SpO2-RR / skinTemp re-chrome.

## Plumbing
- NutritionSummary: `potassiumMg: Double?`
- HK: read `.dietaryPotassium`; cumulativeSum milligrams
- Fixture: today 3600; older 2000…4200; nil every 5th

## Surface
- Today body after Dietary Sodium → **Dietary Potassium**
- Met / Building / Low / Very low vs soft 3400 mg
- A11y: `body.potassium.card`, `body.potassium.baseline`, `body.potassium.spark`

## Verify
- `testDietaryPotassiumTonightBaselineSurface`
- `.audit/verify-dietary-potassium-tonight-baseline.png`
