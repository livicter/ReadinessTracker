# Check-in Insights (Honest #123)

## Intent
Elevate buried morning check-in tags (`subjectiveFeel`, alcohol drinks, stress) into a WHOOP-style **Tonight | Baseline** dual on Today. CheckInStatusCard (#72) Morning/Evening Done wells stay unchanged.

## Surface
- Today → after Morning/Evening check-in wells → **Check-in Insights**
- Tonight feel /5 vs 7-day feel baseline; lifestyle flags caption; 7-day feel spark
- A11y: `checkin.insights.card`, `checkin.insights.baseline`, `checkin.insights.spark`

## Verify
- UITest: `testCheckInInsightsSurface`; shot `.audit/verify-checkin-insights.png`
- Fixture: `MetadataStore.seedUIFixtureCheckIns()` — today feel 4, clear flags; older mornings vary feel/drinks/stress

## Non-goals
- No re-chrome of CheckInStatusCard circular wells
- No caffeine dual (deferred; water already elevated)
