# Simulator A/B snap B (Honest #725)

## Sub-features
- WHOOP wells on the existing A/B snapshot B-row (Save B / Update B, Recall B)
- Idle (`snapB == nil`) Save B = ghost/hairline well (optimal 8% fill + 28% hairline) with caption bold label in secondaryText
- Saved (`snapB != nil`) Update B = filled RTColor.optimal well + white label (same selected treatment as A-row #724, tinted optimal)
- Recall B stays disabled when `snapB == nil`; ghost/hairline when disabled (tertiary text + optimal 8% fill + 28% hairline); enabled = optimal text + optimal 14% fill + hairline
- 0.2s easeInOut keyed on whether snap B exists, matching A-row #724
- SurfaceID `sim.load.ab.snapb` (existing Honest #530; no new SID)
- Clear stays on the A-row (already clears both snaps); not restyled here

## How to get to it (user POV)
Today → Load Simulator → A/B snapshot B-row (Save B / Recall B) below the A-row wells.

## Driving it with the harness
`testReadinessLoadSimulatorSurface` asserts `sim.load.ab.snapb` near the Honest #530 / #725 block (fallback "Save B" / "Update B" labels), taps Save B, and `saveShot("verify-simulator-ab-snapb.png")` alongside `verify-readiness-load-simulator-snap-b.png`.

## Gotchas
This restyles the existing B-row buttons only. Do not restyle lever-diff (`sim.load.ab.leverdiff`, Honest #533) or the A→B/Live Δ READY readout — those are later siblings. Actions, labels, haptics, disabled rules, projectedCoupled snap payload, and accessibility identifiers stay Honest #530. No new SurfaceID or READY formula. Clear lives on the A-row.
