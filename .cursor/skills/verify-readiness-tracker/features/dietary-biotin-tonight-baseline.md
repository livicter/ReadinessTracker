# Dietary Biotin Tonight|Baseline (Honest #210)

## Why
1. Prefer `dietaryBiotin` — last clear leftover B-vitamin after pantothenic acid.
2. Higher-is-better soft ~30 mcg RDA-style goal.
3. After Pantothenic Acid — avoids sleep-stack / SpO2-RR / skinTemp re-chrome.

## Plumbing
- NutritionSummary: `biotinMcg: Double?`
- HK: read `.dietaryBiotin`; cumulativeSum micrograms
- Fixture: today 35; older 12…55; nil every 5th

## Surface
- Today body after Pantothenic Acid → **Dietary Biotin**
- Met / Building / Low / Very low vs soft 30 mcg
- A11y: `body.biotin.card`, `body.biotin.baseline`, `body.biotin.spark`

## Verify
- `testDietaryBiotinTonightBaselineSurface`
- `.audit/verify-dietary-biotin-tonight-baseline.png`
