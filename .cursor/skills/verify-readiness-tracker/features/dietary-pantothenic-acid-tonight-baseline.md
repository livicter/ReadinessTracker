# Pantothenic Acid Tonight|Baseline (Honest #209)

## Why
1. Prefer `dietaryPantothenicAcid` — next leftover B-vitamin after niacin.
2. Higher-is-better soft ~5 mg RDA-style goal.
3. After Dietary Niacin — avoids sleep-stack / SpO2-RR / skinTemp re-chrome.

## Plumbing
- NutritionSummary: `pantothenicAcidMg: Double?`
- HK: read `.dietaryPantothenicAcid`; cumulativeSum milligrams
- Fixture: today 5.5; older 2.0…8.0; nil every 5th

## Surface
- Today body after Dietary Niacin → **Pantothenic Acid**
- Met / Building / Low / Very low vs soft 5 mg
- A11y: `body.pantothenic.card`, `body.pantothenic.baseline`, `body.pantothenic.spark`

## Verify
- `testDietaryPantothenicAcidTonightBaselineSurface`
- `.audit/verify-dietary-pantothenic-acid-tonight-baseline.png`
