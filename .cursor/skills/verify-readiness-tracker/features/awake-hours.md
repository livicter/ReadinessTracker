# Awake Hours (Honest #116)

## Intent
Elevate `awakePercent × timeInBed` (same formula as Sleep Analysis / Day Detail) into a WHOOP-style **Tonight | Baseline** dual callout on the Today WHOOP sleep stack. Distinct from **Wake Episodes** (count) and **Sleep Latency** (onset minutes); Time in Bed’s gap caption is a composite, not this stage-awake duration.

## Surface
- Today → WHOOP sleep stack → **Awake Hours** (after Time in Bed, before Wake Episodes)
- A11y: `sleep.awake.card`, `sleep.awake.baseline`, `sleep.awake.spark`

## Verify
- UITest: `testAwakeHoursSurface` asserts title, Tonight, Baseline; shot `.audit/verify-awake-hours.png`
- Fixture: `awakePercent` derived from stage awake ÷ derived in-bed so spark follows wakeCount variation; today ~1 short awake (~Minimal)

## Non-goals
- No new readiness score term
- Wake Episodes count card unchanged
- Sleep Latency onset card unchanged
