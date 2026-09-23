# Today Check-in status wells

## Sub-features
- Morning|Evening `CheckInStatusCard` on Today
- Each card leading SF Symbol uses a circular tint well

## How to get to it (user POV)
1. Open Today
2. See Morning / Evening check-in status cards near the top
3. Icons sit in circular tint wells (done = accent, pending = tertiary)

## Driving it with the harness
- UITest: `SurfacesUITests.testTodayHeroBright`
- Captures `.audit/verify-dashboard.png`

## Gotchas
- Keep Done/Pending semantics and half-width card layout
- Do not invent Fitness+ chrome; Gym/Work/Sleep + rings + GOOD TO GO stay
