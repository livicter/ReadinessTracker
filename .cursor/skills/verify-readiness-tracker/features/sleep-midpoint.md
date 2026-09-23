# Sleep Midpoint (Honest #114)

## Intent
Elevate unused `sleepStartTime` / `sleepEndTime` into a WHOOP-style **Tonight | Baseline** sleep midpoint dual callout on the Today WHOOP sleep stack, with Early / Intermediate / Late chronotype band and 7-night midpoint spark.

## Surface
- Today → WHOOP sleep stack → **Sleep Midpoint** (after Wake Episodes)
- A11y: `sleep.midpoint.card`, `sleep.midpoint.baseline`, `sleep.midpoint.spark`

## Verify
- UITest: `testSleepMidpointSurface` asserts title, Tonight, Baseline; shot `.audit/verify-sleep-midpoint.png`
- Fixture: today bed 23:05 / wake 07:10 → midpoint ~03:07 (Intermediate); older nights vary bed/wake so spark has shape

## Non-goals
- No new readiness score term
- Sleep Consistency bedtime/wake dual unchanged
- No Munich MSF questionnaire / questionnaire-only chronotype
