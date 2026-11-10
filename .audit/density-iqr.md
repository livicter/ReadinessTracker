# Honest #576 / #658 / #804: Density IQR meter (WHOOP wells)

Fitbit/Health air density Q1–Q3 + median IQR meter immediately after the skew meter on the Air card (below heatmap + WoW + forecast + streak + spark + hist + CV + skew; next unstyled meter body in the hist → gain/pain stack is the percentile meter).
Chrome-only WHOOP wells on the existing Honest #576 / #658 IQR meter container.
The Q1–Q3 band already encodes the IQR reading itself (accent track, tone-filled Q1–Q3 capsule, and primary-text median tick at x = med * w). That band is left intact — not flattened to a uniform 8/14 wash.
Idle (no density > 0 in the 14d window) = ghost/hairline 8/28 secondaryText; active complete (has density, Tight, iqrPP <= 12) = 14/28 optimal; active negative (Wide, iqrPP > 22) = 14/28 strain; else/partial (Steady, 12 < iqrPP <= 22) = 14/28 accent.
The verb capsule keeps its existing tone (Tight / iqrPP <= 12 / optimal, Steady / 12 < iqrPP <= 22 / good, Wide / iqrPP > 22 / warning). Label contrast holds (no white text on a light wash).
Copy, accessibilityIdentifier, accessibilityLabel, IQR math, and READY formula unchanged. No new SID.
SurfaceID: `fitbit.air.density.iqr` / `health.air.density.iqr`
Proof: `.audit/verify-density-iqr.png`
