# Apple Move Time Tonight|Baseline (Honest #164)

## Why
1. Prefer `appleMoveTime` — completes Activity ring trio with Exercise Time + Stand Hours.
2. Strain/activity after Stand Hours — not sleep-stack dual; not chrome-only.

## Plumbing
- Model: `appleMoveTimeMinutes: Double?`
- HK: read `.appleMoveTime`; sum minutes
- Fixture: today 48; older 20…74; nil every 5th

## Surface
- Today strain after Stand Hours → **Move Time**
- Met / Solid / Light / Low vs ≥45 / ≥30 / ≥15 min
- A11y: `strain.moveTime.card`, `strain.moveTime.baseline`, `strain.moveTime.spark`

## Verify
- `testAppleMoveTimeTonightBaselineSurface`
- `.audit/verify-apple-move-time-tonight-baseline.png`
