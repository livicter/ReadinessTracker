# Simulator lever sensitivity bars

## Sub-features
- BarMark per Sleep/HRV/Strain/RHR/SpO₂ contribution
- Σ capsule
- WHOOP wells: idle (all contributions == 0) ghost/hairline 8/28 secondaryText; active negative (sum < 0) strain; active positive (sum > 0) optimal; active mixed (some nonzero AND sum == 0) accent
- SurfaceID `sim.load.lever.sensitivity`

## How to get to it (user POV)
Today → Load Simulator → Lever sensitivity under lever delta chips.

## Driving it with the harness
`testReadinessLoadSimulatorSurface` asserts sensitivity SurfaceID and `saveShot("verify-simulator-lever-sensitivity.png")`.

## Gotchas
Always mounted; values animate with scrub levers.
