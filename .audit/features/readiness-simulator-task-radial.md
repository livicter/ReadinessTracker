# Honest #573 / #760: Simulator task completion radial (WHOOP wells)

Donut of checked vs remaining READY lift (Google Health graphics).
Idle (doneLift == 0) = ghost/hairline 8/28 using secondaryText; active partial (0 < frac < 1) = 14 fill + 28 hairline (accent); active complete (frac >= 1) = 14 fill + 28 hairline (optimal).
SurfaceID: `sim.load.tasks.radial`
Proof: `.audit/verify-simulator-task-radial.png`
UITest: `testReadinessLoadSimulatorSurface`
