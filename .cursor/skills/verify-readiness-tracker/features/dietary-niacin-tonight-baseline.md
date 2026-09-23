# Dietary Niacin Tonight|Baseline (Honest #208)

## Why
1. Prefer `dietaryNiacin` — next leftover B-vitamin after riboflavin.
2. Higher-is-better soft ~16 mg RDA-style goal.
3. After Dietary Riboflavin — avoids sleep-stack / SpO2-RR / skinTemp re-chrome.

## Plumbing
- NutritionSummary: `niacinMg: Double?`
- HK: read `.dietaryNiacin`; cumulativeSum milligrams
- Fixture: today 18; older 8…28; nil every 5th

## Surface
- Today body after Dietary Riboflavin → **Dietary Niacin**
- Met / Building / Low / Very low vs soft 16 mg
- A11y: `body.niacin.card`, `body.niacin.baseline`, `body.niacin.spark`

## Verify
- `testDietaryNiacinTonightBaselineSurface`
- `.audit/verify-dietary-niacin-tonight-baseline.png`
