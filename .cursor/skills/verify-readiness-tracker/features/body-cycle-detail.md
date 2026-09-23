# Body Cycle detail

## Sub-features
- Today Body Cycle tile (when cycle tracking is on)
- Cycle detail sheet: today flow status, 14-day flow strip, readiness −3 note
- Circular tint wells on hero + readiness cue (Apple Health pink)

## How to get to it (user POV)
1. Settings → enable Track menstrual cycle (fixture turns this on under `-ui-fixture`)
2. Today → scroll to Body → Cycle tile → sheet

## Driving it with the harness
- `SurfacesUITests.testBodyCycleDetailSurface` → `.audit/verify-body-cycle.png`
- Soft asserts on `body.tile.cycle` / `body.cycle.detail` / Flow|No flow / Last 14 days

## Gotchas
- Readiness/Recovery still use the existing −3 flow adjustment — detail explains it, does not invent new scoring
- Keep Gym/Work/Sleep + rings + source pills; no Fitness+ invent
- Fixture seeds `menstrualFlow` for offset ≤ 2 so the strip has shape
