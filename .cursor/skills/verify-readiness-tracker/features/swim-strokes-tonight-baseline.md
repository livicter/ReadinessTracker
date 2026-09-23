# Swim Strokes Tonight|Baseline (Honest #153)

## Why
1. Pair with #152 swim distance — `swimmingStrokeCount` unused sparse activity (prefer over underwater depth / cycling cadence).
2. Body stack after Swim Distance — not sleep-stack dual; not chrome-only.

## Plumbing
- Model: `swimmingStrokeCount: Double?`
- HK: read `.swimmingStrokeCount`; cumulativeSum; count
- Fixture: today 820; older 280…1179; nil every 5th

## Surface
- Today body after Swim Distance → **Swim Strokes**
- High / Solid / Light / Low vs ≥1000 / ≥600 / ≥300
- A11y: `body.swimStrokes.card`, `body.swimStrokes.baseline`, `body.swimStrokes.spark`

## Verify
- `testSwimStrokesTonightBaselineSurface`
- `.audit/verify-swim-strokes-tonight-baseline.png`
