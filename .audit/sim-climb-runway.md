# Honest #623 / #748: Simulator climb runway (WHOOP wells)

Queue covers Optimal gap (Hold/Taxi/Roll/Rotate/Airborne).
Idle (Hold / covered < 0.33) = ghost/hairline 8/28; active Taxi (covered >= 0.33) = 14 fill + 28 hairline (caution); Roll (covered >= 0.66) = 14 fill + 28 hairline (good); Rotate (covered >= 1.0) and Airborne (gap == 0) = 14 fill + 28 hairline (optimal).
SurfaceID: `sim.load.ready.climb.runway`
Proof: `.audit/verify-simulator-climb-runway.png`
