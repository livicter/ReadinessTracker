# Today Journal button well

## Sub-features
- Today Journal NavigationLink row
- `book.closed.fill` in circular tint well (was rounded rect)

## How to get to it (user POV)
1. Open Today
2. Find Journal row
3. Leading icon is a circular tint well

## Driving it with the harness
- UITest: `SurfacesUITests.testJournalButtonSurface`
- Captures `.audit/verify-journal-button.png`

## Gotchas
- Keep subtitle “Track behaviors…” and chevron
- Do not invent Fitness+ chrome
