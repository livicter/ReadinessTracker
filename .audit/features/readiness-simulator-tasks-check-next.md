# Honest #551 / #771: Simulator task check next (WHOOP wells)

Always-visible Check next capsule on Today’s tasks action row.
Tap checks the highest `readyDelta` unchecked task (no-op when none).
Idle (no unchecked READY-impact task / nextTarget == nil) = ghost/hairline 8/28 using secondaryText; active negative (nextTarget.readyDelta < 0) = 14/28 strain; active positive (nextTarget.readyDelta >= 0) = 14/28 accent.
SurfaceID: `sim.load.tasks.checknext`
Proof: UITest → `.audit/verify-simulator-check-next.png`
