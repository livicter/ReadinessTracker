# Honest #523 / #777: Simulator air-gap tasks (WHOOP wells)

Cue strip for Fitbit/Health air-gap tasks on Today’s Load Simulator.
Idle (count > 0 && none checked) = ghost/hairline 8/28 using secondaryText; active complete (all air-gap items checked) = 14/28 optimal; active negative (sum of those items’ `readyDelta` < 0, not complete) = 14/28 strain; else (partial) = 14/28 accent.
SurfaceID: `sim.load.tasks.airgaps`
Proof: UITest → `.audit/verify-readiness-load-simulator-airgap-tasks.png`
