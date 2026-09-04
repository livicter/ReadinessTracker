# UI / WHOOP / Google Health parity

Date: 2026-09-05
Branch: `feature/ui-whoop-google-parity`
Base: `main` @ 979105c

## Visual contract
Bright Apple Health. Canvas `#F2F2F7`, white cards, dark labels. Selected chips are dark text on `#E5E5EA` or white text on a filled accent (`RTColor.optimal`). Never white on `surfaceHighlight`.

## Data rules
- WHOOP is HealthKit-detected (`detectDataSource()` contains "whoop"). No Partner API. No third `DataSource` case.
- Google Health on iOS is HealthKit breadth (steps, activity minutes + calories, SpO2, nutrition, optional cycle).
- Fitbit stays OAuth via gitignored `Secrets.xcconfig`. Placeholders rejected.

## Sleep need
`BaselineManager.sleepNeed(from:)` is the 14-night average of recorded sleep hours (same helper as `sleepBaseline` with window 14, fallback 7.5h). UI caption: "Need is your 14-night average."

## Recovery wheel
`RecoveryCalculator.calculate(from:history:)` (0-100), not `DualReadinessScores.general`.
