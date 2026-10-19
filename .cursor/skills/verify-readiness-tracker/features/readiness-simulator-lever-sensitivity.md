# Simulator lever sensitivity bars

## Sub-features
- BarMark per Sleep/HRV/Strain/RHR/SpO₂ contribution
- Σ capsule
- SurfaceID `sim.load.lever.sensitivity`

## How to get to it (user POV)
Today → Load Simulator → Lever sensitivity under lever delta chips.

## Driving it with the harness
`testReadinessLoadSimulatorSurface` asserts sensitivity SurfaceID and `saveShot("verify-simulator-lever-sensitivity.png")`.

## Gotchas
Always mounted; values animate with scrub levers.
