# Dietary Calcium Tonight|Baseline (Honest #198)

## Why
1. Prefer `dietaryCalcium` — clear leftover micronutrient after iron.
2. Higher-is-better soft ~1000 mg RDA-style goal.
3. After Dietary Iron — avoids sleep-stack / SpO2-RR / skinTemp re-chrome.

## Plumbing
- NutritionSummary: `calciumMg: Double?`
- HK: read `.dietaryCalcium`; cumulativeSum milligrams
- Fixture: today 980; older 500…1400; nil every 5th

## Surface
- Today body after Dietary Iron → **Dietary Calcium**
- Met / Building / Low / Very low vs soft 1000 mg
- A11y: `body.calcium.card`, `body.calcium.baseline`, `body.calcium.spark`

## Verify
- `testDietaryCalciumTonightBaselineSurface`
- `.audit/verify-dietary-calcium-tonight-baseline.png`
