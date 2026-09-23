# Cycling Speed Tonight | Baseline

Honest #222. Net-new Tonight|Baseline card for HealthKit `cyclingSpeed` (m/s → `cyclingSpeedMps`).

Completes cycling set (cadence / power / FTP / distance already shipped).

## Surfaces
- `body.cyclingSpeed.card`
- `body.cyclingSpeed.baseline`
- `body.cyclingSpeed.spark`

## Verify
- UITest: `testCyclingSpeedTonightBaselineSurface`
- Screenshot: `verify-cycling-speed-tonight-baseline.png`

## Soft bands
Brisk ≥8.0 m/s · Steady ≥6.0 · Easy ≥4.0
