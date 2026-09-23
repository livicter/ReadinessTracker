# Watch dual-callout wells

## Sub-features
- Compact circular tint wells on Watch/widget dual callouts:
  - WatchSleepChrome Hours|Eff
  - CompactStrainRecoveryWheel Recovery|Strain
  - CompactTripleRingsView HRV|RHR

## How to get to it (user POV)
1. Apple Watch Sleep / Strain / Dashboard surfaces (or audit chrome renders)

## Driving it with the harness
- `scripts/capture-watch-sleep.sh` → `.audit/verify-watch-sleep.png`
- `scripts/capture-watch-strain.sh` → `.audit/verify-watch-strain.png`
- Dashboard capture refreshes HRV|RHR chrome when run

## Gotchas
- Wells are 18pt for Watch density (phone duals stay 22–26pt)
- No Fitness+ invent; keep Gym/Work/Sleep + Recovery 0–100 / Strain 0–21
