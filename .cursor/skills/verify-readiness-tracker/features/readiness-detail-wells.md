# Readiness Detail wells

## Sub-features
- Recommendation lightbulb circular tint well
- Component rows circular tint wells (was rounded rect)

## How to get to it (user POV)
1. Today → open readiness / score detail
2. See Recommendation + Component Detail with circular wells

## Driving it with the harness
- UITest: `SurfacesUITests.testReadinessDetailSurface`
- Captures `.audit/verify-readiness-detail.png`

## Gotchas
- Empty chart state icon stays large / soft (not a chrome well)
- Do not invent Fitness+ chrome
