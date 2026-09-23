# Error banner well

## Sub-features
- Today error banner circular tint well on warning triangle

## How to get to it (user POV)
1. Today when a sync/HealthKit error surfaces
2. Banner shows circular tint well + message + Retry

## Driving it with the harness
- UITest: `SurfacesUITests.testErrorBannerWellSurface` (soft — fixture may omit banner)
- Captures `.audit/verify-error-banner.png`

## Gotchas
- Soft harness: banner is conditional; shot still proves Today chrome
- Do not invent Fitness+ chrome
