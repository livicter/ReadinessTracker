# Time in Daylight Tonight|Baseline (Honest #139)

## Why
1. Watch recovery already on Today wheel + breakdown.
2. `timeInDaylight` unused sparse HK — stronger circadian signal than UV for this elevation.

## Plumbing
- `timeInDaylightMinutes: Double?`
- HK `.timeInDaylight` cumulative minutes
- Fixture today 95; history 35…124; nil every 5th

## Surface
- Today vitals after Sound Reduction → **Time in Daylight**
- A11y `vitals.daylight.*`

## Verify
- `testTimeInDaylightTonightBaselineSurface`
- `.audit/verify-time-in-daylight-tonight-baseline.png`
