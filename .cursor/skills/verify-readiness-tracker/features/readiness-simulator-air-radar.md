# Simulator air coverage radar (Honest #593 / #733)

## Sub-features
- Sleep · Vitals · Move fill radar + percent capsule
- WHOOP wells: idle (no filled fields) = ghost/hairline 8%/28%; active (some filled) = 14% fill + 28% hairline in accent; all fields filled = same active well but optimal tone
- SurfaceID `sim.load.air.radar` (existing Honest #593; no new SID)

## How to get to it (user POV)
Today → Load Simulator → Air coverage under Impact share.

## Driving it with the harness
`testReadinessLoadSimulatorSurface` asserts SurfaceID near the Honest #593 / #733 block and `saveShot("verify-simulator-air-radar.png")`.

## Gotchas
Hidden when air chips are empty.
This restyles existing `airCoverageRadarBody` chrome only. Keep dot.radiowaves.left.and.right icon, "Air coverage" label, source/percent capsule, radar arcs, category pills, footer (Sleep · Vitals · Move), padding(10), cornerRadius 12, SID, per-category identifiers (`sim.load.air.radar.<cat>`), accessibilityIdentifier, accessibilityLabel ("Air coverage \(pct) percent, \(filled) of \(total) fields"), animation, and fill formula (filled/total * 100).
Idle (no filled fields) uses ghost 8%/28% secondaryText; active uses 14% fill + 28% hairline (accent, or optimal if all filled).
No new SurfaceID or fill formula.
