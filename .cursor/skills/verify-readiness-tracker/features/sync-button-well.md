# Sync button well

## Sub-features
- Today SyncStatusView Sync control circular tint well

## How to get to it (user POV)
1. Open Today
2. Sync row under the source picker shows a circular well on the refresh icon

## Driving it with the harness
- UITest: `SurfacesUITests.testSyncButtonWellSurface`
- Captures `.audit/verify-sync-button.png`

## Gotchas
- Keep spinning animation on the icon while syncing
- Do not invent Fitness+ chrome
