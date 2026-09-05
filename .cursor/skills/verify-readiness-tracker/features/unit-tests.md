# Unit tests

## New coverage
- `BaselineManagerTests.testSleepNeedIs14NightAverageNotTenPercentFudge`
- `RecoveryCalculatorTests` asserts `dashboardWheelScore` equals recovery total

## Command
```bash
DESTINATION='platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' ./scripts/ci-verify.sh
```
Fallback: omit DESTINATION.
