# Honest #580 / #668 / #806: Density envelope chart (WHOOP wells)

Chrome-only WHOOP wells on the existing density envelope chart (`fitbit.air.density.envelope` / `health.air.density.envelope`).
The Chart already encodes the envelope reading itself (Q1–Q3 AreaMark at meterColor.opacity(0.14), density LineMark, and dashed median RuleMark) and is left intact (not flattened to a uniform 8/14 wash).
Idle (no density > 0 in the 14d window) = ghost/hairline 8/28 secondaryText; active complete (has density, Tight, iqrPP <= 12) = 14/28 optimal; active negative (Wide, iqrPP > 22) = 14/28 strain; else/partial (Steady, 12 < iqrPP <= 22) = 14/28 accent.
The IQR capsule keeps its existing meterColor tone. Copy, accessibilityIdentifier, accessibilityLabel, envelope math, and READY formula unchanged.
SurfaceID: `fitbit.air.density.envelope` / `health.air.density.envelope`
Proof: UITest → `.audit/verify-density-envelope.png`
