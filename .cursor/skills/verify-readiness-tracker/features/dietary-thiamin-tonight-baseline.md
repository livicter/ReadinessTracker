# Dietary Thiamin Tonight|Baseline (Honest #206)

## Why
1. Prefer `dietaryThiamin` — first leftover B-vitamin after B6.
2. Higher-is-better soft ~1.2 mg RDA-style goal.
3. After Vitamin B6 — avoids sleep-stack / SpO2-RR / skinTemp re-chrome.

## Plumbing
- NutritionSummary: `thiaminMg: Double?`
- HK: read `.dietaryThiamin`; cumulativeSum milligrams
- Fixture: today 1.4; older 0.4…2.2; nil every 5th

## Surface
- Today body after Vitamin B6 → **Dietary Thiamin**
- Met / Building / Low / Very low vs soft 1.2 mg
- A11y: `body.thiamin.card`, `body.thiamin.baseline`, `body.thiamin.spark`

## Verify
- `testDietaryThiaminTonightBaselineSurface`
- `.audit/verify-dietary-thiamin-tonight-baseline.png`
