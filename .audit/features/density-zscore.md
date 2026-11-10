# Honest #588 / #664 / #810: Density z-score strip (WHOOP wells)

Chrome-only WHOOP wells on the existing density z-score strip (`fitbit.air.density.zscore` / `health.air.density.zscore`).
The signed −3σ…+3σ gradient track, mean tick, and tone-filled needle already encode the z-score reading and are left intact (not flattened to a uniform 8/14 wash).
Idle (no density > 0 in the 14d window) = ghost/hairline 8/28 secondaryText; active complete (has density, Typical, abs(z) < 0.75) = 14/28 optimal; active negative (Hot or Cold, abs(z) >= 1.5) = 14/28 strain; else/partial (High or Low, 0.75 <= abs(z) < 1.5) = 14/28 accent.
The verb capsule keeps its existing tone. Copy, accessibilityIdentifier, accessibilityLabel, z-score math, and READY formula unchanged.
SurfaceID: `fitbit.air.density.zscore` / `health.air.density.zscore`
Proof: UITest → `.audit/verify-density-zscore.png`
