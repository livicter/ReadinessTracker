# Post-Strain Recovery Trajectory (Honest #238)

## Intent
WHOOP parity: after hard strain days, show average Recovery on Day+1…Day+N vs personal baseline.
Elevates unused `TrendAnalysisEngine.recoveryTrajectory` — prior Recovery Pattern chart used metric self-deviation only and ignored strain.

## Surface
- Today → WHOOP Recovery & Strain stack → **Post-Strain Recovery** (after Daily TRIMP)
- Also Recovery & Strain detail + Metric Detail / Advanced Metric Detail (activeCalories strain proxy)
- A11y: `recovery.postStrain.card`, `recovery.postStrain.chart`, `recovery.postStrain.events`

## Verify
- UITest: `testPostStrainRecoveryTrajectorySurface` asserts title + card id; shot `.audit/verify-post-strain-recovery-trajectory.png`
- Fixture: 14-day UI seed with varying strain so mean-threshold yields hard days

## Non-goals
- No new readiness score term
- No bloodAlcoholContent / new HK quantity duals
- No chrome-only re-skin of Strain vs Recovery history chart
