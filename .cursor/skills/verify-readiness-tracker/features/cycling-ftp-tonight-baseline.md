# Cycling FTP Tonight|Baseline (Honest #157)

## Why
1. Pair with #156 cyclingPower — `cyclingFunctionalThresholdPower` unused fitness threshold HK.
2. Body/activity after Cycling Power — not sleep-stack dual; not chrome-only.

## Plumbing
- Model: `cyclingFTPWatts: Double?`
- HK: read `.cyclingFunctionalThresholdPower`; discreteAverage; watts; iOS 17+
- Fixture: today 250; older 220…269; nil every 5th

## Surface
- Today body after Cycling Power → **Cycling FTP**
- High / Solid / Building / Low vs ≥280 / ≥230 / ≥180 W
- A11y: `body.cyclingFTP.card`, `body.cyclingFTP.baseline`, `body.cyclingFTP.spark`

## Verify
- `testCyclingFTPTonightBaselineSurface`
- `.audit/verify-cycling-ftp-tonight-baseline.png`
