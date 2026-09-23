# Sleep Latency (Honest #109)

## Intent
Elevate `sleepOnsetMinutes` (previously only a buried Sleep Analysis timing chip) into a WHOOP / Apple Health–style Tonight | Baseline card on the Today WHOOP sleep stack, with Fast/Typical/Slow band and 7-night spark.

## Surface
- Today → WHOOP sleep stack → **Sleep Latency** (after Sleep Performance)
- A11y: `sleep.latency.card`, `sleep.latency.baseline`, `sleep.latency.spark`

## Verify
- UITest: `testSleepLatencySurface` asserts title, Tonight, Baseline; shot `.audit/verify-sleep-latency.png`
- Fixture: today 12 min; older nights vary 8…35 so spark has shape

## Non-goals
- No new readiness score term
- No sleep-stage hypnogram changes
