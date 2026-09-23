# Toothbrushing Tonight|Baseline (Honest #185)

## Why
1. Prefer `toothbrushingEvent` — unused hygiene-sparse HK category.
2. Total duration (minutes) clearer than event count for adherence (~2×2 min).
3. After Basal Energy — not chrome-only; avoids sleep-stack duals.

## Plumbing
- Model: `toothbrushingMinutes: Double?` on DailyHealthData
- HK: read `.toothbrushingEvent`; sum sample durations → minutes
- Fixture: today 4.2; older 1.5…4.9; nil every 5th

## Surface
- Today body after Basal Energy → **Toothbrushing**
- Met / Steady / Building / Light / Missed vs soft 4 min + baseline
- A11y: `body.brush.card`, `body.brush.baseline`, `body.brush.spark`

## Verify
- `testToothbrushingTonightBaselineSurface`
- `.audit/verify-toothbrushing-tonight-baseline.png`
