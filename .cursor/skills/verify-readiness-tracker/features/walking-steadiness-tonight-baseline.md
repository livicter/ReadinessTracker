# Walking Steadiness Tonight|Baseline (Honest #166)

## Why
1. Prefer `appleWalkingSteadiness` over `heartRateRecoveryOneMinute` — finishes gait set with balance; more everyday coverage than sparse HRR.
2. Body after Step Length — not sleep-stack dual; not chrome-only.

## Plumbing
- Model: `walkingSteadinessPercent: Double?` (HK percent → 0…100)
- HK: read `.appleWalkingSteadiness`; discreteAverage; fraction→%
- Fixture: today 78; older 45…94; nil every 5th

## Surface
- Today body after Step Length → **Walk Steadiness**
- OK / Fair / Low / Very Low vs ≥70 / ≥50 / ≥30 %
- A11y: `body.steadiness.card`, `body.steadiness.baseline`, `body.steadiness.spark`

## Verify
- `testWalkingSteadinessTonightBaselineSurface`
- `.audit/verify-walking-steadiness-tonight-baseline.png`
