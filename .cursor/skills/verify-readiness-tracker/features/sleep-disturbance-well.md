# Today Sleep Stages disturbance well

## Sub-features
- Sleep Stages card disturbance cue on Today
- Leading SF Symbol uses a circular tint well (optimal ≤2 wakes, caution otherwise)

## How to get to it (user POV)
1. Open Today
2. Scroll to Sleep Stages
3. See “N disturbances” with a circular tint warning well

## Driving it with the harness
- UITest: `SurfacesUITests.testSleepDisturbanceSurfaceVisibleAfterScroll`
- Captures `.audit/verify-sleep-disturbances.png`

## Gotchas
- Keep accessibility label “Sleep disturbances”
- Do not invent Fitness+ chrome
