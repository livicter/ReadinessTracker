# Dietary Folate Tonight|Baseline (Honest #201)

## Why
1. Prefer `dietaryFolate` — clear leftover micronutrient after mineral stack.
2. Higher-is-better soft ~400 mcg RDA-style goal.
3. After Dietary Zinc — avoids sleep-stack / SpO2-RR / skinTemp re-chrome.

## Plumbing
- NutritionSummary: `folateMcg: Double?`
- HK: read `.dietaryFolate`; cumulativeSum micrograms
- Fixture: today 420; older 180…600; nil every 5th

## Surface
- Today body after Dietary Zinc → **Dietary Folate**
- Met / Building / Low / Very low vs soft 400 mcg
- A11y: `body.folate.card`, `body.folate.baseline`, `body.folate.spark`

## Verify
- `testDietaryFolateTonightBaselineSurface`
- `.audit/verify-dietary-folate-tonight-baseline.png`
