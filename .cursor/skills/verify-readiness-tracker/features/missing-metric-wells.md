# Missing metric wells

## Sub-features
- MissingMetricRow circular tint well when overnight Respiratory Rate / Skin Temperature (etc.) are absent

## How to get to it (user POV)
1. Today → scroll WHOOP vitals stack
2. When a metric was not recorded last night, the row shows a circular tint well + title + "Not recorded last night"

## Driving it with the harness
- UITest: `SurfacesUITests.testMissingMetricWellSurface`
- Captures `.audit/verify-missing-metric.png`

## Gotchas
- Live RespiratoryRateCard / SkinTemperatureCard already have wells when data exists
- Do not invent Fitness+ chrome
