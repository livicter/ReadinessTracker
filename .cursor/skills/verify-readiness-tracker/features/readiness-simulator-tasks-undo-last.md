# Simulator task undo last

## Sub-features
- Always-visible Undo last capsule on Today’s tasks action row
- Tap unchecks the highest `readyDelta` checked task; no-op when none (haptic still OK)
- WHOOP wells: idle (`undoTarget == nil`) ghost/hairline 8/28 secondaryText; active negative (`undoTarget.readyDelta < 0`) 14/28 strain `FF375F`; active positive (`undoTarget.readyDelta >= 0`) 14/28 accent
- SurfaceID `sim.load.tasks.undolast`

## How to get to it (user POV)
Today → Load Simulator → Today’s tasks row → Undo last capsule (next to Check next).

## Driving it with the harness
`testReadinessLoadSimulatorSurface` waits for `sim.load.tasks.undolast`, taps, `saveShot("verify-simulator-undo-last.png")`.

## Gotchas
This ship restyles chrome only; pick (highest readyDelta checked), uncheck action, and SurfaceID/accessibility label are unchanged. Always-visible so idle can render (a visibility guard would mean visibility == has-checked == always-active). Styled by the single undo target, same as next-preview styles by `next.readyDelta`. No mixed state.
