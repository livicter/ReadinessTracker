# Readiness simulator climb glide

## Sub-features
- Climb glide dial (Above/On path/Lag/Below)
- SurfaceID `sim.load.ready.climb.glide`

## How to get to it (user POV)
Today → Load Simulator → past climb runway → Climb glide

## Driving it with the harness
UITest asserts `sim.load.ready.climb.glide` and saves `.audit/verify-simulator-climb-glide.png`.

## Gotchas
Empty when no pending tasks.
