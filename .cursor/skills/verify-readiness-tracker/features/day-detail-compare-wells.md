# Day Detail compare wells

## Sub-features
- Sleep Cycles summary circular tint well (was rounded square)
- vs Previous Day Recovery Context circular tint well

## How to get to it (user POV)
1. History → day row → Day Detail
2. Sleep Cycles row + Recovery Context "vs Previous Day" show circular tint wells

## Driving it with the harness
- UITest: `SurfacesUITests.testDayDetailCompareWellSurface`
- Captures `.audit/verify-day-detail-compare.png`

## Gotchas
- Empty-state large bed glyph stays soft / decorative
- Stage % / metric chip wells already shipped in Honest #79
- Do not invent Fitness+ chrome
