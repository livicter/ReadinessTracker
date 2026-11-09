# Honest #720 / #786: Simulator tasks row (WHOOP wells)

Chrome-only WHOOP wells on existing Honest #720 task row.
Idle (!isDone) = ghost/hairline 8/28 using secondaryText; active complete (isDone && readyDelta >= 0) = 14/28 optimal; active negative (isDone && readyDelta < 0) = 14/28 strain.
Check-well, leading 3pt rail, toggle, SID, labels, and READY formula unchanged.
SurfaceID: `sim.load.tasks.row`
Proof: UITest → `.audit/verify-simulator-tasks-row.png`
