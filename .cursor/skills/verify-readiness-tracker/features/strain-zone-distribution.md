# Strain Zone Distribution (Honest #239)

## Intent
WHOOP / Google Health parity: multi-day **days-in-soft-band** distribution for the 0–21 strain score.
Elevates unused `TrendAnalysisEngine.zoneDistribution`. Complements Heart Rate Zones (today minute bins)
and Watch Strain (Tonight|Baseline) without re-chroming either.

## Soft bands (same as Watch Strain)
- Rest 0–2.999 · Light 3–5.999 · Moderate 6–9.999 · Hard 10–13.999 · All out 14–21

## Surface
- Today → WHOOP Recovery & Strain → **Strain Zones** (after Watch Strain)
- Also Recovery & Strain detail (after Heart Rate Zones)
- A11y: `strain.zoneDist.card|bar|rest|light|moderate|hard|allOut`

## Verify
- UITest: `testStrainZoneDistributionSurface`; shot `.audit/verify-strain-zone-distribution.png`
- Fixture: 14-day strain history yields non-empty distribution

## Non-goals
- No new HK quantity / bloodAlcoholContent
- No re-ship of recoveryTrajectory or HeartRateZonesCard minute logic
