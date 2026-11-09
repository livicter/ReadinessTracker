# Honest #553 / #770: Simulator task undo last (WHOOP wells)

Always-visible Undo last capsule on Today’s tasks action row.
Tap unchecks the highest `readyDelta` checked task (no-op when none).
Idle (no checked READY-impact task / undoTarget == nil) = ghost/hairline 8/28 using secondaryText; active negative (undoTarget.readyDelta < 0) = 14/28 strain; active positive (undoTarget.readyDelta >= 0) = 14/28 accent.
SurfaceID: `sim.load.tasks.undolast`
Proof: `.audit/verify-simulator-undo-last.png`
