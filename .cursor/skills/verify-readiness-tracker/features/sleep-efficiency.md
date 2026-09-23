# Sleep Efficiency (Honest #110)

## Intent
Elevate `sleepEfficiency` (previously only a buried Sleep Analysis timing chip / Sleep Performance one-liner) into a WHOOP / Apple Health–style Tonight | Baseline card on the Today WHOOP sleep stack, with Excellent/Good/Fair/Poor band and 7-night spark.

## Surface
- Today → WHOOP sleep stack → **Sleep Efficiency** (after Sleep Latency)
- A11y: `sleep.efficiency.card`, `sleep.efficiency.baseline`, `sleep.efficiency.spark`

## Verify
- UITest: `testSleepEfficiencySurface` asserts title, Tonight, Baseline; shot `.audit/verify-sleep-efficiency.png`
- Fixture: today 0.91 (91%); older nights vary 0.78…0.94 so spark has shape

## Non-goals
- No new readiness score term
- No change to Sleep Performance Need|Got (Efficiency stays a one-liner there too)
