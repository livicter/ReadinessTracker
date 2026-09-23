# Time in Bed (Honest #115)

## Intent
Elevate derived time-in-bed hours (`sleepHours ÷ sleepEfficiency`, same as Day Detail / Sleep Analysis) into a WHOOP-style **Tonight | Baseline** dual callout on the Today WHOOP sleep stack, with each column stacking **In Bed** + **Asleep** — beyond Need|Got and Efficiency %.

## Surface
- Today → WHOOP sleep stack → **Time in Bed** (after Sleep Efficiency)
- A11y: `sleep.inbed.card`, `sleep.inbed.baseline`, `sleep.inbed.spark`

## Verify
- UITest: `testTimeInBedSurface` asserts title, Tonight, Baseline, In Bed, Asleep; shot `.audit/verify-time-in-bed.png`
- Fixture: today 7.4h @ 91% → ~8.1h in bed; older nights vary hours/efficiency so spark has shape

## Non-goals
- No new readiness score term
- Sleep Performance Need|Got unchanged
- Sleep Efficiency % card unchanged
