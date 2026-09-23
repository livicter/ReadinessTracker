# Running Speed Tonight|Baseline (Honest #160)

## Why
1. Finish run-intensity pair after #159 runningPower — `runningSpeed` unused sparse run pace HK.
2. Body/activity after Running Power — not sleep-stack dual; not chrome-only (distinct from walkingSpeed).

## Plumbing
- Model: `runningSpeedMps: Double?`
- HK: read `.runningSpeed`; discreteAverage; m/s; iOS 16+
- Fixture: today 3.15; older 2.40…3.59; nil every 5th

## Surface
- Today body after Running Power → **Running Speed**
- Brisk / Steady / Easy / Slow vs ≥3.3 / ≥2.8 / ≥2.2 m/s
- A11y: `body.runningSpeed.card`, `body.runningSpeed.baseline`, `body.runningSpeed.spark`

## Verify
- `testRunningSpeedTonightBaselineSurface`
- `.audit/verify-running-speed-tonight-baseline.png`
