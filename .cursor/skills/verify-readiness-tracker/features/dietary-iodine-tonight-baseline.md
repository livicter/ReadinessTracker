# Dietary Iodine Tonight|Baseline (Honest #214)

## Why
1. Prefer `dietaryIodine` — next leftover mineral after manganese.
2. Higher-is-better soft ~150 mcg RDA-style goal.
3. After Dietary Manganese — avoids sleep-stack / SpO2-RR / skinTemp re-chrome.

## Plumbing
- NutritionSummary: `iodineMcg: Double?`
- HK: read `.dietaryIodine`; cumulativeSum micrograms
- Fixture: today 160; older 60…250; nil every 5th

## Surface
- Today body after Dietary Manganese → **Dietary Iodine**
- Met / Building / Low / Very low vs soft 150 mcg
- A11y: `body.iodine.card`, `body.iodine.baseline`, `body.iodine.spark`

## Verify
- `testDietaryIodineTonightBaselineSurface`
- `.audit/verify-dietary-iodine-tonight-baseline.png`
