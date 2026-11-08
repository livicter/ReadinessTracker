# Simulator A/B snap (Honest #724)

## Sub-features
- WHOOP wells on the existing A/B snapshot A-row (Save A / Update A, Recall A, Clear)
- Idle (`snapA == nil`) Save A = ghost/hairline well (accent 8% fill + 28% hairline) with caption bold label in secondaryText
- Saved (`snapA != nil`) Update A = filled accent well + white label (same selected treatment as #721/#722/#723)
- Recall A stays disabled when `snapA == nil`; ghost/hairline when disabled (tertiary text + accent 8% fill + 28% hairline); enabled = accent text + accent 14% fill + hairline
- Clear uses #721 Reset-secondary treatment (secondary text, surfaceHighlight fill, divider stroke)
- 0.2s easeInOut keyed on whether snap A exists, matching #721–#723
- SurfaceID `sim.load.ab.snap` (existing Honest #520; no new SID)

## How to get to it (user POV)
Today → Load Simulator → A/B snapshot row (Save A / Recall A / Clear) below the seed wells.

## Driving it with the harness
`testReadinessLoadSimulatorSurface` asserts `sim.load.ab.snap` near the Honest #520 block (fallback "Save A" label), taps Save A, and `saveShot("verify-simulator-ab-snap.png")` alongside `verify-readiness-load-simulator-ab-snapshot.png`.

## Gotchas
This restyles the existing A-row buttons only. Do not restyle the second HStack (Save B / Update B / Recall B) — that is SID `sim.load.ab.snapb` (Honest #530), the next sibling. `abLeverDiffRow`, A→B/Live Δ READY readout, actions, labels, haptics, disabled rules, and accessibility identifiers stay Honest #520. No new SurfaceID or READY formula.
