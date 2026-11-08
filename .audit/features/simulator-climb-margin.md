# Honest #712 / #751: Simulator climb margin (WHOOP wells)

SurfaceID: `sim.load.ready.climb.margin`
Idle Short (margin < 0, queue never reaches Optimal) = ghost/hairline 8/28; active Exact (margin == 0) = 14 fill + 28 hairline (caution); active Soft (margin >= 1) = 14 fill + 28 hairline (good); active Clear (margin >= 8) = 14 fill + 28 hairline (optimal).
Proof: `.audit/verify-simulator-climb-margin.png`
UITest: `testReadinessLoadSimulatorSurface`
