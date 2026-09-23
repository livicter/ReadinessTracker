# Recovery Zone Distribution (Honest #245)

## Intent
WHOOP signature **Green / Yellow / Red** multi-day recovery days-in-zone.
Elevates `TrendAnalysisEngine.zoneDistribution` on Recovery wheel scores (0–100).
Distinct from Strain Zones (#239 Rest→All out). Introduces `RecoveryZone` enum.

## Soft bands (WHOOP classic)
- Green 67–100 · Yellow 34–66.999 · Red 0–33.999

## Surface
- Today → WHOOP stack → **Recovery Zones** (after Post-Strain Recovery)
- Also Recovery & Strain detail (after post-strain trajectory)
- A11y: `recovery.zoneDist.card|bar|green|yellow|red`

## Verify
- UITest: `testRecoveryZoneDistributionSurface`; shot `.audit/verify-recovery-zone-distribution.png`

## Non-goals
- No re-chrome of StrainZoneDistributionCard
- No Metric Detail overlay re-ships / BAC / new HK duals
