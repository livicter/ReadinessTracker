# Cycling Power Tonight|Baseline (Honest #156)

## Why
1. Prefer `cyclingPower` over `cyclingFunctionalThresholdPower` — day avg watts is a Tonight|Baseline effort signal; FTP is a slower-moving fitness constant.
2. Body/activity after Underwater Depth — not sleep-stack dual; not chrome-only.

## Plumbing
- Model: `cyclingPowerWatts: Double?`
- HK: read `.cyclingPower`; discreteAverage; watts; iOS 17+
- Fixture: today 195; older 140…259; nil every 5th

## Surface
- Today body after Underwater Depth → **Cycling Power**
- Strong / Solid / Easy / Low vs ≥220 / ≥170 / ≥120 W
- A11y: `body.cyclingPower.card`, `body.cyclingPower.baseline`, `body.cyclingPower.spark`

## Verify
- `testCyclingPowerTonightBaselineSurface`
- `.audit/verify-cycling-power-tonight-baseline.png`
