# Dietary Riboflavin Tonight|Baseline (Honest #207)

## Why
1. Prefer `dietaryRiboflavin` — next leftover B-vitamin after thiamin.
2. Higher-is-better soft ~1.3 mg RDA-style goal.
3. After Dietary Thiamin — avoids sleep-stack / SpO2-RR / skinTemp re-chrome.

## Plumbing
- NutritionSummary: `riboflavinMg: Double?`
- HK: read `.dietaryRiboflavin`; cumulativeSum milligrams
- Fixture: today 1.5; older 0.5…2.4; nil every 5th

## Surface
- Today body after Dietary Thiamin → **Dietary Riboflavin**
- Met / Building / Low / Very low vs soft 1.3 mg
- A11y: `body.riboflavin.card`, `body.riboflavin.baseline`, `body.riboflavin.spark`

## Verify
- `testDietaryRiboflavinTonightBaselineSurface`
- `.audit/verify-dietary-riboflavin-tonight-baseline.png`
