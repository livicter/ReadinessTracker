# Waist Circumference Tonight|Baseline (Honest #183)

## Why
1. Prefer `waistCircumference` — last unused body-composition after lean mass.
2. Latest cm vs 7-day baseline; metabolic-adjacent without sleep-stack duals.
3. After Lean Body Mass — not chrome-only.

## Plumbing
- Model: `waistCircumferenceCm: Double?` on DailyHealthData
- HK: read `.waistCircumference`; mostRecent meter → ×100 for cm
- Fixture: today 81.2; older 79.0…84.0; nil every 5th

## Surface
- Today body after Lean Body Mass → **Waist Circumference**
- Steady / Down / Up vs |Δ|<0.5 / down / up
- A11y: `body.waist.card`, `body.waist.baseline`, `body.waist.spark`

## Verify
- `testWaistCircumferenceTonightBaselineSurface`
- `.audit/verify-waist-circumference-tonight-baseline.png`
