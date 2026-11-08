# Simulator presets (Honest #721)

## Sub-features
- Equal-width segmented wells for Rest / Easy / Push / Reset
- Selected = filled well + contrasting label (accent fill + white for Rest/Easy/Push; surfaceHighlight + primaryText for Reset)
- Unselected = ghost/hairline well (accent 8% + 28% hairline; Reset is clear + divider hairline)
- Selected state by matching current lever values (sleep / hrv / strain / rhr / spo2) to the existing preset formulas — no new READY metric
- 0.2s easeInOut on the matched preset token, matching #719/#720 animation
- SurfaceID `sim.load.presets` (existing Honest #504; no new SID)

## How to get to it (user POV)
Today → Load Simulator → Rest/Easy/Push/Reset capsule row directly under the card header, above the #718 bipolar sliders.

## Driving it with the harness
`testReadinessLoadSimulatorSurface` asserts `sim.load.presets` near the Honest #504 block (fallback Rest button/label), taps the Rest well (~0.15) then Reset (~0.9), optionally checks Rest isSelected, and `saveShot("verify-simulator-presets.png")`.

## Gotchas
This restyles the existing preset row only; lever formulas stay Honest #504 (SimulatorPreset sleep/hrv/strain/rhr/spo2). Reset still clears completedTaskIDs, airSeededSummary, and snapA. No new SurfaceID.
