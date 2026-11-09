# Honest #719 / #785: Simulator tasks bar (WHOOP wells)

WHOOP-parity segmented task completion bar (one segment per task, filled from completedTaskIDs; caption N/M + percent) on Today’s Load Simulator.
Idle (taskTotal == 0 OR done == 0 / none checked) = ghost/hairline 8/28 using secondaryText; active complete = 14/28 optimal; else (partial progress) = 14/28 accent.
SurfaceID: `sim.load.tasks.bar`
Proof: UITest → `.audit/verify-simulator-tasks-bar.png`
