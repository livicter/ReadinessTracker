# Restorative Sleep (Honest #111)

## Intent
Elevate Deep + REM stage percents (already on Sleep Stages bar / labels) into hours on a WHOOP-style **Deep | REM** dual callout on the Today WHOOP sleep stack, with Rich/Solid/Fair/Low band and 7-night restorative spark.

## Surface
- Today → WHOOP sleep stack → **Restorative Sleep** (after Sleep Efficiency)
- A11y: `sleep.restorative.card`, `sleep.restorative.dual`, `sleep.restorative.spark`

## Verify
- UITest: `testRestorativeSleepSurface` asserts title, Deep, REM; shot `.audit/verify-restorative-sleep.png`
- Fixture: today Deep 17% / REM 21% on 7.4h (~1.3h / ~1.6h); older nights vary so spark has shape

## Non-goals
- No new readiness score term
- No change to Sleep Stages bar / Day Detail hypnogram
- Resting HR MetricCard left as-is (still a thinner Metrics tile; candidate for #112)
