# Cycling Distance Tonight|Baseline (Honest #165)

## Why
1. Prefer `distanceCycling` — completes cycling set with cadence / power / FTP (volume gap).
2. Body/activity after Cycling FTP — not sleep-stack dual; not chrome-only.

## Plumbing
- Model: `distanceCyclingKm: Double?` (HK meters / 1000)
- HK: read `.distanceCycling`; sum meters → km
- Fixture: today 28.5; older 8…52; nil every 5th

## Surface
- Today body after Cycling FTP → **Cycling Distance**
- Long / Solid / Light / Low vs ≥40 / ≥20 / ≥8 km
- A11y: `body.cyclingDistance.card`, `body.cyclingDistance.baseline`, `body.cyclingDistance.spark`

## Verify
- `testCyclingDistanceTonightBaselineSurface`
- `.audit/verify-cycling-distance-tonight-baseline.png`
