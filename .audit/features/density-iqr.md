# Honest #576 / #658 / #804: Density IQR meter (WHOOP wells)

Chrome-only WHOOP wells on the existing density IQR meter (`fitbit.air.density.iqr` / `health.air.density.iqr`).
The Q1–Q3 band already encodes the IQR reading itself (accent track, tone-filled Q1–Q3 capsule, and primary-text median tick) and is left intact (not flattened to a uniform 8/14 wash).
Idle (no density > 0 in the 14d window) = ghost/hairline 8/28 secondaryText; active complete (has density, Tight, iqrPP <= 12) = 14/28 optimal; active negative (Wide, iqrPP > 22) = 14/28 strain; else/partial (Steady, 12 < iqrPP <= 22) = 14/28 accent.
Verb capsule keeps its existing tone. Copy, accessibilityIdentifier, accessibilityLabel, IQR math, and READY formula unchanged.
SurfaceID: `fitbit.air.density.iqr` / `health.air.density.iqr`
Proof: UITest → `.audit/verify-density-iqr.png`
