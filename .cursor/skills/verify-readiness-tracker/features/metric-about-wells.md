# Metric About wells

## Sub-features
- Metric Detail "Why can't I see older data?" info cue circular tint well
- Advanced Metric Detail "About This Data" info cue circular tint well

## How to get to it (user POV)
1. Today → Metrics → open a metric → scroll to About / older-data card
2. Info SF Symbol sits in a circular tint well (matches Skin Temperature cue)

## Driving it with the harness
- UITest: `SurfacesUITests.testMetricAboutWellSurface`
- Captures `.audit/verify-metric-about.png`

## Gotchas
- Empty-state large chart glyphs stay soft / decorative
- Toggle chips stay Capsule/check, not wells
- Do not invent Fitness+ chrome
