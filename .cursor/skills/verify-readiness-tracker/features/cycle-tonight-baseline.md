# Cycle Tonight|Baseline (Honest #120)

## Intent
Elevate buried `menstrualFlow` into a WHOOP-style **Tonight | Baseline** dual on Today Body — beyond the Cycle tile’s “Flow reported / No flow” chip. CycleDetailView sheet (Honest #101) is unchanged.

## Surface
- Today → Body → **Cycle** dual card (when cycle tracking is on; after the Body tile grid)
- Tonight: Flow / None (+ readiness −3 caption when flowing)
- Baseline: days with flow in last 7
- A11y: `body.cycle.card`, `body.cycle.baseline`, `body.cycle.spark`

## Verify
- UITest: `testCycleTonightBaselineSurface`; shot `.audit/verify-cycle-tonight-baseline.png`
- Fixture: `trackMenstrualCycle = true`; `menstrualFlow` for offset ≤ 2 so spark shows active → clear

## Non-goals
- No re-chrome of CycleDetailView sheet
- Steps dual deferred (Body tile already shows steps)
