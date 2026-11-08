# Honest #609 / #741: Simulator READY zone buffer

Pts to next zone up/down + inside-band fill (Near/Climb/Hold/Capped) (WHOOP wells).
Idle (Hold) = ghost/hairline 8%/28%; active (Climb) = 14% fill + 28% hairline (good); Near/Capped = 14% fill + 28% hairline (optimal).
SurfaceID: `sim.load.ready.buffer` (existing; no new SID)
Proof: `.audit/verify-simulator-ready-buffer.png`
