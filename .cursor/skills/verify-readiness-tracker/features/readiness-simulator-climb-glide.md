# Readiness simulator climb glide

## Sub-features
- Climb glide dial (Above/On path/Lag/Below)
- SurfaceID `sim.load.ready.climb.glide`
- WHOOP wells: idle Below (meanDev < -2) = ghost/hairline 8%/28%; active Lag (meanDev >= -2) = 14% fill + 28% hairline (caution); On path (meanDev >= 1) = 14% fill + 28% hairline (good); Above (meanDev >= 4) = 14% fill + 28% hairline (optimal)

## How to get to it (user POV)
Today → Load Simulator → past climb runway → Climb glide

## Driving it with the harness
UITest asserts `sim.load.ready.climb.glide` and saves `.audit/verify-simulator-climb-glide.png`.

## Gotchas
Empty when no pending tasks.
Idle Below uses secondaryText ghost/hairline (8%/28%); Lag/On path/Above keep existing verb tones with 14% fill + 28% hairline. No formula / verb / threshold / metric change.
