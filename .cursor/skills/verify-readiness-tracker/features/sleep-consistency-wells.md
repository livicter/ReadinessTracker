# Today Sleep Consistency wells

## Sub-features
- Bedtime|Wake dual columns on Sleep Consistency card
- Each column title uses a circular tint SF Symbol well (moon / sunrise style)

## How to get to it (user POV)
1. Open Today
2. Scroll the WHOOP stack to **Sleep Consistency**
3. See Bedtime and Wake dual columns with circular icon wells

## Driving it with the harness
- UITest: `SurfacesUITests.testSleepQualitySurfaceVisibleAfterScroll`
- Captures `.audit/verify-sleep-quality.png` (Consistency sits with Sleep Quality Trend)

## Gotchas
- Do not invent Fitness+ chrome; keep Gym/Work/Sleep + rings + GOOD TO GO
- Wells match other Honest Apple chrome (26pt circle, tint opacity ~0.14)
