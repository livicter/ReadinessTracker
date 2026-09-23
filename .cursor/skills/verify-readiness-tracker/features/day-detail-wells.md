# Day Detail stage + metric wells

## Sub-features
- Sleep stage detail rows (Deep/REM/Core/Awake)
- Day Detail metric chips
- Circular tint SF Symbol wells (was rounded rect / bare)

## How to get to it (user POV)
1. History → day row (or Today → Sleep Stages)
2. Open Day / Sleep Analysis detail
3. Stage rows and metric chips use circular tint wells

## Driving it with the harness
- UITest: `SurfacesUITests.testDayDetailSurface`
- Captures `.audit/verify-day-detail.png`

## Gotchas
- Keep optimal checkmark / caution glyph on the trailing side
- Do not invent Fitness+ chrome
