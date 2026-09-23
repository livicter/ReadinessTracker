# Apple Stand Hours Tonight|Baseline (Honest #144)

## Why
1. Survey: Watch Activity rings — Move (active cal) + Exercise Time already elevated; Stand Hours unused.
2. `appleStandHour` strongest unused Watch-beyond-rings field (not sleep-stack dual).

## Plumbing
- Model: `appleStandHours: Double?`
- HK: read `.appleStandHour` category; count samples with `.stood`
- Fixture: today 10; older 4…12; nil every 5th

## Surface
- Today strain stack after Exercise Time → **Stand Hours**
- Met / Solid / Light / Low vs 12-hr guide
- A11y: `strain.standHours.card`, `strain.standHours.baseline`, `strain.standHours.spark`

## Verify
- `testAppleStandHoursTonightBaselineSurface`
- `.audit/verify-apple-stand-hours-tonight-baseline.png`
