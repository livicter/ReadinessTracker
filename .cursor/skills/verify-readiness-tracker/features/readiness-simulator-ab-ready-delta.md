# Simulator A/B READY delta gauge (Honest #581 / #727)

## Sub-features
- Dual-tick span gauge A/Base vs B/Live (always mounts; Base→Live fallback when no snap A)
- WHOOP wells: zero Δ = ghost/hairline 8%/28%; nonzero Δ = signed tone 14% fill + 28% hairline
- Track as a ghost well; span between A and B uses the signed tone; A tick secondary, B tick accent
- SurfaceID `sim.load.ab.ready.delta` (existing Honest #581; no new SID)

## How to get to it (user POV)
Today → Load Simulator → A/B READY Δ under lever polarity.

## Driving it with the harness
`testReadinessLoadSimulatorSurface` asserts SurfaceID near the Honest #581 / #727 block and `saveShot("verify-simulator-ab-ready-delta.png")`.

## Gotchas
Always mounts (falls back to Base→Live when no snap A). Do not gate behind snapA.
This restyles existing `abReadyDeltaGauge` chrome only. Keep header copy, icons, footer labels, signed Δ text, formula, colors-for-sign, animations, and accessibility identifier/label.
Do not restyle Save A / Save B rows (#724 / #725) or abLeverDiffRow chips (#726).
Do not restyle the unlabeled inline HStack inside abSnapshotBlock (`A {ready} → {B|Live} {ready}` + ±N READY capsule) — that HStack has no SID.
No new SurfaceID, zone bands, or READY formula.
