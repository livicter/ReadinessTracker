# Journal Impact Tonight|Baseline (Honest #124)

## Intent
Elevate Journal Behavior Impact (alcohol / stress / recovery tags + readiness) onto Today as a **Tonight | Baseline** dual. JournalView’s Behavior Impact rows (#82 circular wells) remain the deep dive — not re-chromed. Journal button remains navigation chrome.

## Surface
- Today → after Check-in Insights → **Journal Impact** (before Journal button)
- Tonight: today’s journal readiness + behavior tags; Baseline: avg readiness across journal days; 7-day spark
- A11y: `journal.impact.card`, `journal.impact.baseline`, `journal.impact.spark`

## Verify
- UITest: `testJournalImpactTonightBaselineSurface`; shot `.audit/verify-journal-impact-tonight-baseline.png`
- Fixture: `UIFixture.seedJournalEntries()` — today Massage @ 80; older days vary alcohol/stress/recovery

## Non-goals
- No re-chrome of Journal Behavior Impact circular wells (#82 test unchanged)
- No caffeine Tonight|Baseline (deferred)
