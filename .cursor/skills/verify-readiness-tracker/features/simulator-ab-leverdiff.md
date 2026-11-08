# Simulator A/B lever diff (Honest #726)

## Sub-features
- WHOOP wells on the existing A/B lever-diff chips (`abLeverDiffRow`)
- Focused (selected) chip = filled kind.color well + white icon/title/delta, no stroke (same selected treatment as saved Update A/B)
- Unfocused + zero delta = ghost/hairline well (kind.color 8% fill + 28% hairline) with kind.color icon/title/delta
- Unfocused + nonzero delta = kind.color 14% fill + 28% hairline + kind.color label (same enabled Recall A/B treatment)
- 0.2s easeInOut keyed on focusedLever and whether each delta is zero
- SurfaceID `sim.load.ab.leverdiff` (existing Honest #533; no new SID)
- Caption stays "A → Live levers" / "A → B levers"; tap still sets focusedLever + Haptic.selectionChanged(); abLeverDeltaText formats unchanged
- Do not restyle the A→B/Live Δ READY readout HStack just above the chips, or the Save A / Save B rows

## How to get to it (user POV)
Today → Load Simulator → Save A (and optionally Save B) → A/B lever-diff chips under the A→B/Live Δ READY readout.

## Driving it with the harness
`testReadinessLoadSimulatorSurface` asserts `sim.load.ab.leverdiff` near the Honest #533 / #726 block (fallback label containing "levers"), taps a chip, and `saveShot("verify-simulator-ab-leverdiff.png")` alongside `verify-readiness-load-simulator-ab-lever-diff.png`.

## Gotchas
This restyles the existing lever-diff chips only. Do not restyle the A→B/Live Δ READY readout (`A {ready} → {B|Live} {ready}` + ±N READY capsule) — that is the next sibling (`sim.load.ab.ready.delta`, Honest #581). Do not restyle Save A / Save B rows (already #724 / #725). Actions, labels, haptics, abLeverDeltaText formats, and accessibility identifiers stay Honest #533. No new SurfaceID or READY formula.
