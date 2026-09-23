# Running Power Tonight|Baseline (Honest #159)

## Why
1. Prefer `runningPower` over `runningSpeed` — stronger run-intensity signal after physicalEffort (finish run-intensity pair next with speed).
2. Body/activity after Physical Effort — not sleep-stack dual; not chrome-only.

## Plumbing
- Model: `runningPowerWatts: Double?`
- HK: read `.runningPower`; discreteAverage; watts; iOS 16+
- Fixture: today 268; older 200…319; nil every 5th

## Surface
- Today body after Physical Effort → **Running Power**
- Strong / Solid / Easy / Low vs ≥300 / ≥240 / ≥180 W
- A11y: `body.runningPower.card`, `body.runningPower.baseline`, `body.runningPower.spark`

## Verify
- `testRunningPowerTonightBaselineSurface`
- `.audit/verify-running-power-tonight-baseline.png`
