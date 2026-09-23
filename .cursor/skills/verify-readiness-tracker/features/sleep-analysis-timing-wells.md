# Sleep Analysis timing wells

## Sub-features
- Sleep Analysis timing cards (Sleep Onset / Time in Bed / Wake Episodes / Sleep Efficiency)
- Leading SF Symbol circular tint wells (~26pt, tint opacity 0.14)

## How to get to it (user POV)
1. Today → Sleep Stages → Sleep Analysis
2. Sleep Timing grid shows circular tint wells on each card icon

## Driving it with the harness
- UITest: `SurfacesUITests.testSleepAnalysisTimingSurface`
- Captures `.audit/verify-sleep-analysis.png`

## Gotchas
- Empty-state large chart icons stay soft / decorative
- Do not invent Fitness+ chrome
