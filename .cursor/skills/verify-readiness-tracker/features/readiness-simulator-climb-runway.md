# Readiness simulator climb runway

## Sub-features
- Climb runway dial on Load Simulator (Hold/Taxi/Roll/Rotate/Airborne)
- SurfaceID `sim.load.ready.climb.runway`

## How to get to it (user POV)
Today → Load Simulator card → scroll past climb surplus → Climb runway

## Driving it with the harness
UITest asserts `sim.load.ready.climb.runway` (fallback surplus/sim.load) and saves `.audit/verify-simulator-climb-runway.png`.

## Gotchas
Empty when no pending tasks. Fitbit vs Health source label.
