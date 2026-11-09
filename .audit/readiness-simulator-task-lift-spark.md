# Honest #549 / #772: Simulator task READY lift spark (WHOOP wells)

Cumulative READY lift BarMark spark — bars tint `RTColor.optimal` when the task is in `completedTaskIDs`, else `accent.opacity(0.28)`.
Idle (no checked lift contributions: `lift == 0` and nothing checked, or every checked `readyDelta == 0`) = ghost/hairline 8/28 using secondaryText; active negative (`lift < 0`) = 14/28 strain; active positive (`lift > 0`) = 14/28 optimal; active mixed (some checked nonzero AND `lift == 0`) = 14/28 accent.
SurfaceID: `sim.load.tasks.liftspark`
Proof: `.audit/verify-readiness-load-simulator-task-lift-spark.png`
