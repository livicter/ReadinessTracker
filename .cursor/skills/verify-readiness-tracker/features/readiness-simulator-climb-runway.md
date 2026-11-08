# Readiness simulator climb runway

## Sub-features
- Climb runway dial on Load Simulator (Hold/Taxi/Roll/Rotate/Airborne)
- SurfaceID `sim.load.ready.climb.runway`
- WHOOP wells: idle Hold (covered < 0.33) = ghost/hairline 8%/28%; active Taxi (covered >= 0.33) = 14% fill + 28% hairline (caution); Roll (covered >= 0.66) = 14% fill + 28% hairline (good); Rotate (covered >= 1.0) and Airborne (gap == 0) = 14% fill + 28% hairline (optimal)

## How to get to it (user POV)
Today → Load Simulator card → scroll past climb surplus → Climb runway

## Driving it with the harness
UITest asserts `sim.load.ready.climb.runway` (fallback surplus/sim.load) and saves `.audit/verify-simulator-climb-runway.png`.

## Gotchas
Empty when no pending tasks. Fitbit vs Health source label.
Idle Hold uses secondaryText ghost/hairline (8%/28%); Taxi/Roll/Rotate/Airborne keep existing verb tones with 14% fill + 28% hairline. No formula / verb / threshold / metric change.
