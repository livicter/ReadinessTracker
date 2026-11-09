# Simulator projected ring chips (Honest #508 / #781)

## Sub-features
- Projected Gym / Work / Sleep / READY chips that track lever scrubs; tap focuses caption
- WHOOP wells on the existing outer chip stack: idle (all four ring deltas == 0) ghost/hairline 8/28 secondaryText; active negative (some nonzero AND READY delta < 0) 14/28 strain; active positive (some nonzero AND READY delta > 0) 14/28 optimal; active mixed (some nonzero AND READY delta == 0) 14/28 accent
- SurfaceID `sim.load.rings`

## How to get to it (user POV)
Today → Load Simulator card → scroll to projected ring chips (always visible, below Lever sensitivity / lever deltas).

## Driving it with the harness
`testReadinessLoadSimulatorSurface` asserts `sim.load.rings` and `saveShot("verify-readiness-load-simulator-rings.png")`.

## Gotchas
This ship restyles the outer well chrome only — copy, chip interaction, focus (`focusedRing`), visibility, accessibilityIdentifier, and accessibilityLabel are unchanged. Individual inner chip fills (`kind.color` focused, `kind.color.opacity(0.12)` unfocused) are not restyled. Well tone follows the #761 ring-deltas READY-delta convention (not the sum of ring deltas). READY chip on this surface shows uncoupled `projected` (Honest #508), so readyDelta = `projected - baseline` (`scores.general`); Gym `projectedGym - scores.gym`; Work `projectedWork - scores.cognitive`; Sleep `projectedSleep - scores.breakdown.sleepScore`. Do not restyle `sim.load.ring.deltas` (#575 / #761); that sibling already has WHOOP wells on coupled READY (`projectedCoupled - baseline`). Do not invent a new SID.
