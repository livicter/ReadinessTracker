# Honest #712 / #751: Simulator climb margin (WHOOP wells)

Optimal clearance at intercept (or queue end if short). Clear/Soft/Exact/Short dial + signed pts bar.
Idle Short (margin < 0, queue never reaches Optimal) = ghost/hairline 8/28; active Exact (margin == 0) = 14 fill + 28 hairline (caution); active Soft (margin >= 1) = 14 fill + 28 hairline (good); active Clear (margin >= 8) = 14 fill + 28 hairline (optimal).
SurfaceID: `sim.load.ready.climb.margin`
Proof: `.audit/verify-simulator-climb-margin.png`
