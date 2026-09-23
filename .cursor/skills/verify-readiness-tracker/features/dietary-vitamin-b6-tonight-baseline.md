# Vitamin B6 Tonight|Baseline (Honest #205)

## Why
1. Prefer `dietaryVitaminB6` — clear leftover B-vitamin after vitamin K.
2. Higher-is-better soft ~1.7 mg RDA-style goal.
3. After Vitamin K — avoids sleep-stack / SpO2-RR / skinTemp re-chrome.

## Plumbing
- NutritionSummary: `vitaminB6Mg: Double?`
- HK: read `.dietaryVitaminB6`; cumulativeSum milligrams
- Fixture: today 1.9; older 0.6…2.8; nil every 5th

## Surface
- Today body after Vitamin K → **Vitamin B6**
- Met / Building / Low / Very low vs soft 1.7 mg
- A11y: `body.b6.card`, `body.b6.baseline`, `body.b6.spark`

## Verify
- `testDietaryVitaminB6TonightBaselineSurface`
- `.audit/verify-dietary-vitamin-b6-tonight-baseline.png`
