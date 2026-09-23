# Dietary Copper Tonight|Baseline (Honest #211)

## Why
1. Prefer `dietaryCopper` — first leftover mineral after B-vitamins.
2. Higher-is-better soft ~0.9 mg RDA-style goal.
3. After Dietary Biotin — avoids sleep-stack / SpO2-RR / skinTemp re-chrome.

## Plumbing
- NutritionSummary: `copperMg: Double?`
- HK: read `.dietaryCopper`; cumulativeSum milligrams
- Fixture: today 1.0; older 0.4…1.6; nil every 5th

## Surface
- Today body after Dietary Biotin → **Dietary Copper**
- Met / Building / Low / Very low vs soft 0.9 mg
- A11y: `body.copper.card`, `body.copper.baseline`, `body.copper.spark`

## Verify
- `testDietaryCopperTonightBaselineSurface`
- `.audit/verify-dietary-copper-tonight-baseline.png`
