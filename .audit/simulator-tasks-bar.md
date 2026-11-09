# Honest #719 / #785: Simulator tasks bar (WHOOP wells)

WHOOP-parity segmented task completion bar (one segment per task, filled from completedTaskIDs; caption N/M + percent).
Chrome-only WHOOP wells on the existing Honest #719 HStack.
Idle (taskTotal == 0 OR done == 0 / none checked) = ghost/hairline 8/28 using secondaryText; active complete (allTasksDone) = 14/28 optimal; else (partial progress) = 14/28 accent.
Segment fill math, caption, interaction, accessibilityLabel, and accessibilityIdentifier unchanged.
SurfaceID: `sim.load.tasks.bar`
Proof: `.audit/verify-simulator-tasks-bar.png`
