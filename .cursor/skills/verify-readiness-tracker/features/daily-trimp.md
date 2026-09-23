# Daily TRIMP (Honest #119)

## Intent
Elevate summed `strainSessions.trimp` into a WHOOP-style **Tonight | Baseline** dual callout on the Today Recovery & Strain stack. WorkoutSummaryCard only shows TRIMP in a subtitle / per-session chips on detail — not a daily dual-callout. Complements Workout Minutes (duration).

## Surface
- Today → WHOOP Recovery & Strain → **Daily TRIMP** (after Workout Minutes)
- A11y: `strain.trimp.card`, `strain.trimp.baseline`, `strain.trimp.spark`

## Verify
- UITest: `testDailyTRIMPSurface` asserts title, Tonight, Baseline; shot `.audit/verify-daily-trimp.png`
- Fixture: today Running enriched from HR samples; offsets 1…6 seeded TRIMP (enrich preserves when no HR) so 7-day spark has shape

## Non-goals
- No re-chrome of WorkoutSummaryCard session list
- No new readiness score term
