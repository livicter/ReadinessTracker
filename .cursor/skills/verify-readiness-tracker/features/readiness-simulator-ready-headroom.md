# Simulator READY headroom dial (Honest #595 / #734)

## Sub-features
- READY headroom dial + Tight/Open/Wide verb capsule
- WHOOP wells: idle (no secured task lift) = ghost/hairline 8%/28%; active (some secured lift) = 14% fill + 28% hairline in accent; tight (headroom <= 2) = same active well but optimal tone
- SurfaceID `sim.load.ready.headroom` (existing Honest #595; no new SID)

## How to get to it (user POV)
Today → Load Simulator → READY headroom dial (after air coverage radar).

## Driving it with the harness
`testReadinessLoadSimulatorSurface` asserts SurfaceID near the Honest #595 / #734 block and `saveShot("verify-simulator-ready-headroom.png")`.

## Gotchas
This restyles existing `readyHeadroomDial` chrome only. Keep gauge.with.dots.needle.67percent icon, "READY headroom" label, verb capsule (Tight/Open/Wide +headroom), 64pt dial, Coupled/Ceiling rows, gradient bar, "secured +…" footer, padding(10), cornerRadius 12, SID, accessibilityIdentifier, accessibilityLabel ("READY headroom \(verb), \(headroom) points left"), animation, and every numeric formula.
Idle (no secured task lift) uses ghost 8%/28% secondaryText; active uses 14% fill + 28% hairline (accent, or optimal if headroom <= 2).
No new SurfaceID or READY formula.
