# Journal Log-7-days cue well

## Sub-features
- Journal empty/low-data “Log 7 days…” cue card
- `chart.bar` SF Symbol in circular tint well

## How to get to it (user POV)
1. Open Today → Journal
2. With fewer than 7 entries, see the Log 7 days cue
3. Icon sits in a circular tint well

## Driving it with the harness
- UITest: `SurfacesUITests.testJournalSurface`
- Captures `.audit/verify-journal.png`
- Soft: fixture may seed ≥7 entries; cue may be off-screen — shot still proves Journal chrome

## Gotchas
- Do not invent new habit analytics chrome
- Keep behavior chips as capsules unless a later Honest welds them
