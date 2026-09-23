# Core Sleep (Honest #117)

## Intent
Elevate `lightSleepPercent × sleepHours` into a WHOOP-style **Tonight | Baseline** dual callout on the Today WHOOP sleep stack. Completes stage-hour elevation after Restorative Sleep (Deep|REM); Core/Light was previously only a stage-chip percent.

## Surface
- Today → WHOOP sleep stack → **Core Sleep** (after Restorative Sleep)
- A11y: `sleep.core.card`, `sleep.core.baseline`, `sleep.core.spark`

## Verify
- UITest: `testCoreSleepSurface` asserts title, Tonight, Baseline; shot `.audit/verify-core-sleep.png`
- Fixture: today ~55% Core (Solid, ~4.1h); older nights vary lightSleepPercent so spark has shape

## Non-goals
- No new readiness score term
- Restorative Deep|REM dual unchanged
- Sleep Stages chip bar unchanged
