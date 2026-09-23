# Source picker wells

## Sub-features
- Today source picker (Apple Watch / Fitbit) circular tint wells on icons

## How to get to it (user POV)
1. Open Today
2. Source chips at top show heart / walk icons in circular tint wells

## Driving it with the harness
- UITest: `SurfacesUITests.testSourcePickerWellSurface`
- Captures `.audit/verify-source-picker.png`

## Gotchas
- Selected chip already uses surface highlight; wells stay subtle
- AppIconTile stays rounded-square (Apple Settings list style)
- No Fitness+ invent
