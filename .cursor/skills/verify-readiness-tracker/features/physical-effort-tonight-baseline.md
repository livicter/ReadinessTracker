# Physical Effort Tonight|Baseline (Honest #158)

## Why
1. Prefer `physicalEffort` over `runningPower` / `runningSpeed` — broadest unused readiness intensity HK (not sport-scoped).
2. Body/activity after Cycling FTP — not sleep-stack dual; not chrome-only.

## Plumbing
- Model: `physicalEffortKcalPerHrKg: Double?`
- HK: read `.physicalEffort`; discreteAverage; kcal/hr·kg; iOS 17+
- Fixture: today 3.8; older 1.6…5.5; nil every 5th

## Surface
- Today body after Cycling FTP → **Physical Effort**
- High / Solid / Easy / Low vs ≥5.0 / ≥3.0 / ≥1.5
- A11y: `body.physicalEffort.card`, `body.physicalEffort.baseline`, `body.physicalEffort.spark`

## Verify
- `testPhysicalEffortTonightBaselineSurface`
- `.audit/verify-physical-effort-tonight-baseline.png`
