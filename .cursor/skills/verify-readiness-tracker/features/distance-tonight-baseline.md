# Distance Tonight|Baseline (Honest #142)

## Why
1. Steps already dualled (`StepsTonightBaselineCard`).
2. Watch deepSleepPercent / rem already on Today sleep stack — avoid sleep-stack clones.
3. `distanceWalkingRunning` unused sparse HK — strongest unused live volume signal.

## Plumbing
- Model: `distanceWalkingRunningKm: Double?`
- HK: read `.distanceWalkingRunning`; day cumulativeSum (m → km)
- Fixture: today 6.2 km; older 2.0…9.9; nil every 5th

## Surface
- Today body activity after Flights → **Walking Distance**
- High / Active / Light / Low
- A11y: `body.distance.card`, `body.distance.baseline`, `body.distance.spark`

## Verify
- `testDistanceTonightBaselineSurface`
- `.audit/verify-distance-tonight-baseline.png`
