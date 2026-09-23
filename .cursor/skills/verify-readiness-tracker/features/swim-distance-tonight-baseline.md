# Swim Distance Tonight|Baseline (Honest #152)

## Why
1. Prefer `distanceSwimming` — strongest unused sparse activity volume after 6MWT (clearer than stroke count / underwater depth / cycling cadence).
2. Body stack after Six-Minute Walk — not sleep-stack dual; not chrome-only.

## Plumbing
- Model: `distanceSwimmingMeters: Double?`
- HK: read `.distanceSwimming`; cumulativeSum; meters
- Fixture: today 1200; older 400…1999; nil every 5th

## Surface
- Today body after Six-Minute Walk → **Swim Distance**
- Strong / Solid / Light / Low vs ≥1500 / ≥800 / ≥400 m
- A11y: `body.swimDistance.card`, `body.swimDistance.baseline`, `body.swimDistance.spark`

## Verify
- `testSwimDistanceTonightBaselineSurface`
- `.audit/verify-swim-distance-tonight-baseline.png`
