# Resting Heart Rate (Honest #112)

## Intent
Elevate Resting Heart Rate from the thinner Metrics `MetricCard` into a WHOOP-style **Tonight | Baseline** dual callout on the Today WHOOP vitals stack (before Respiratory Rate), matching RR / Skin / SpO₂ / Latency / Efficiency / Restorative chrome.

## Surface
- Today → WHOOP vitals stack → **Resting Heart Rate** (before Respiratory Rate)
- A11y: `resting.hr.card`, `resting.hr.baseline`, `resting.hr.spark`

## Verify
- UITest: `testRestingHRSurface` asserts title, Tonight, Baseline; shot `.audit/verify-resting-hr.png`
- Fixture: today 54 bpm; older nights vary 50…60 so spark has shape
- Baseline: `BaselineManager.rhrBaseline(from:)`

## Non-goals
- No new readiness score term
- Metrics MetricCard for Resting Heart Rate retained (grid glance)
