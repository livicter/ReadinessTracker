# Honest #580 / #668 / #806: Density envelope chart (WHOOP wells)

Fitbit/Health air density spark with Q1–Q3 envelope of last-14 dens, immediately after the percentile meter on the Air card (below heatmap + WoW + forecast + streak + spark + hist + CV + skew + IQR + percentile; next unstyled meter body in the hist → gain/pain stack is the MAD meter).
Chrome-only WHOOP wells on the existing Honest #580 / #668 envelope chart container.
The Chart already encodes the envelope reading itself (Q1–Q3 AreaMark at meterColor.opacity(0.14), density LineMark, and dashed median RuleMark). That chart is left intact — not flattened to a uniform 8/14 wash.
Idle (no density > 0 in the 14d window) = ghost/hairline 8/28 secondaryText; active complete (has density, Tight, iqrPP <= 12) = 14/28 optimal; active negative (Wide, iqrPP > 22) = 14/28 strain; else/partial (Steady, 12 < iqrPP <= 22) = 14/28 accent.
The IQR capsule keeps its existing meterColor tone. Label contrast holds (no white text on a light wash).
Copy, accessibilityIdentifier, accessibilityLabel, envelope math, and READY formula unchanged. No new SID.
SurfaceID: `fitbit.air.density.envelope` / `health.air.density.envelope`
Proof: `.audit/verify-density-envelope.png`
