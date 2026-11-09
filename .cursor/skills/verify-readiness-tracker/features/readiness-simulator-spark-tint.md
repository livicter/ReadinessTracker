# Simulator spark ring tint (Honest #512 / #782)

## Sub-features
- Projection map bars + header tint follow the focused READY/Gym/Work/Sleep chip
- WHOOP wells on the existing outer projection-map stack: idle (`focusedRingValue == baseline`) ghost/hairline 8/28 secondaryText; active negative (`focusedRingValue < baseline`) 14/28 strain; active positive (`focusedRingValue > baseline`) 14/28 optimal. No mixed state (single signed delta vs tonight baseline).
- Primary SurfaceID `sim.load.spark.tint` on the header HStack; legacy `sim.load.spark` retained on the Chart

## How to get to it (user POV)
Today → Load Simulator card → scroll to the Projection map (always visible, below projected ring chips / ring tint).

## Driving it with the harness
`testReadinessLoadSimulatorSurface` asserts `sim.load.spark.tint` and `saveShot("verify-readiness-load-simulator-spark-tint.png")`.

## Gotchas
This ship restyles the outer well chrome only — copy, header tint Circle (`focusedRing.color`), Chart bar tint (Scrub = `focusedRing.color`, others 0.28), interaction, visibility, accessibilityIdentifier, and accessibilityLabel are unchanged. Well tone follows the focused-ring delta vs tonight baseline (same idea as #781 rings' READY-delta convention, but for `focusedRingValue`). Do not use “any bar != baseline” — the map always shows -2h/+1h/+HRV/−RHR scenarios, so that would never be idle. Do not invent a new SID. Do not restyle the sibling READY path spark (`sim.load.path.spark`, Honest #561 / #766); that surface already has WHOOP wells.
