# Real HRV RMSSD Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Compute RMSSD from HealthKit heartbeat-series RR intervals and use it in place of SDNN for recovery scoring when available.

**Architecture:** Add a focused `HRVCalculator` utility for time-domain HRV math. Extend `HealthKitManager` to query `HKHeartbeatSeriesSample`, extract RR intervals, compute RMSSD, and fall back to SDNN. Update `RecoveryCalculator` semantics and UI labels to reflect the metric source.

**Tech Stack:** Swift 5, HealthKit, SwiftUI, XCTest

## Global Constraints
- iOS deployment target: 16.0+
- No new third-party dependencies
- Keep all data local (UserDefaults / HealthKit)
- Maintain backward compatibility for persisted `DailyHealthData`
- Follow existing dark-themed Apple-native UI patterns (`RTColor`, `GlassCardV2`, `AppleTheme`)

---

## File Map

| File | Responsibility |
|------|----------------|
| `ReadinessTracker/Models/HRVCalculator.swift` | New: RMSSD/SDNN math from RR intervals |
| `ReadinessTrackerTests/HRVCalculatorTests.swift` | New: unit tests for RMSSD/SDNN |
| `ReadinessTracker/Services/HealthKitManager.swift` | Modify: fetch heartbeat series, compute RMSSD, fallback to SDNN |
| `ReadinessTracker/Models/RecoveryCalculator.swift` | Modify: document RMSSD semantics, no math change |
| `ReadinessTracker/Views/DashboardView.swift` | Modify: show "RMSSD" label when `hrvIsRMSSD` |
| `ReadinessTracker/Views/ReadinessScoreDetailView.swift` | Modify: show "RMSSD" label when `hrvIsRMSSD` |

---

### Task 1: Add `HRVCalculator` with RMSSD and SDNN

**Files:**
- Create: `ReadinessTracker/Models/HRVCalculator.swift`

**Interfaces:**
- Produces: `HRVCalculator.rmssd(from: [Double]) -> Double?`
- Produces: `HRVCalculator.sdnn(from: [Double]) -> Double?`

- [ ] **Step 1: Create `HRVCalculator.swift`**

```swift
import Foundation

enum HRVCalculator {
    /// Root mean square of successive differences (RMSSD) in milliseconds.
    static func rmssd(from rrIntervalsMs: [Double]) -> Double? {
        guard rrIntervalsMs.count >= 2 else { return nil }
        let diffs = zip(rrIntervalsMs.dropFirst(), rrIntervalsMs).map { $0 - $1 }
        let squared = diffs.map { $0 * $0 }
        let mean = squared.reduce(0, +) / Double(squared.count)
        return sqrt(mean)
    }

    /// Standard deviation of NN intervals (SDNN) in milliseconds.
    static func sdnn(from rrIntervalsMs: [Double]) -> Double? {
        guard rrIntervalsMs.count >= 2 else { return nil }
        let mean = rrIntervalsMs.reduce(0, +) / Double(rrIntervalsMs.count)
        let variance = rrIntervalsMs.map { pow($0 - mean, 2) }.reduce(0, +) / Double(rrIntervalsMs.count)
        return sqrt(variance)
    }
}
```

- [ ] **Step 2: Build to verify it compiles**

Run:
```bash
xcodebuild -project ReadinessTracker.xcodeproj -scheme ReadinessTracker -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -configuration Debug build 2>&1 | tail -20
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add ReadinessTracker/Models/HRVCalculator.swift
git commit -m "feat: add HRVCalculator with RMSSD and SDNN"
```

---

### Task 2: Unit tests for `HRVCalculator`

**Files:**
- Create: `ReadinessTrackerTests/HRVCalculatorTests.swift`

**Interfaces:**
- Consumes: `HRVCalculator.rmssd(from:)`, `HRVCalculator.sdnn(from:)`

- [ ] **Step 1: Create the test file**

```swift
import XCTest
@testable import Readiness

final class HRVCalculatorTests: XCTestCase {
    func testRMSSDFromKnownRRIntervals() {
        // Successive differences: 10, -20, 10
        // Squared: 100, 400, 100 -> mean 200 -> sqrt 200 ≈ 14.142
        let rr: [Double] = [1000, 1010, 990, 1000]
        let result = HRVCalculator.rmssd(from: rr)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!, 14.142, accuracy: 0.001)
    }

    func testRMSSDLessThanTwoIntervalsReturnsNil() {
        XCTAssertNil(HRVCalculator.rmssd(from: [1000]))
        XCTAssertNil(HRVCalculator.rmssd(from: []))
    }

    func testSDNNFromKnownRRIntervals() {
        let rr: [Double] = [1000, 1010, 990, 1000]
        // mean = 1000, variance = (0 + 100 + 100 + 0)/4 = 50, sd = sqrt(50) ≈ 7.071
        let result = HRVCalculator.sdnn(from: rr)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!, 7.071, accuracy: 0.001)
    }

    func testSDNNLessThanTwoIntervalsReturnsNil() {
        XCTAssertNil(HRVCalculator.sdnn(from: [1000]))
        XCTAssertNil(HRVCalculator.sdnn(from: []))
    }
}
```

- [ ] **Step 2: Run tests to verify they pass**

Run:
```bash
xcodebuild -project ReadinessTracker.xcodeproj -scheme ReadinessTracker -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -configuration Debug test 2>&1 | tail -40
```

Expected: `HRVCalculatorTests` passes, total tests ≥ 9.

- [ ] **Step 3: Commit**

```bash
git add ReadinessTrackerTests/HRVCalculatorTests.swift
git commit -m "test: add HRVCalculator RMSSD/SDNN tests"
```

---

### Task 3: Fetch heartbeat series and compute RMSSD in `HealthKitManager`

**Files:**
- Modify: `ReadinessTracker/Services/HealthKitManager.swift`

**Interfaces:**
- Produces: `HealthKitManager.fetchHeartbeatSeriesRRIntervals(predicate:) -> [Double]`
- Produces: `HealthKitManager.fetchRMSSD(predicate:) -> (value: Double, isRMSSD: Bool)`
- Consumes: `HRVCalculator.rmssd(from:)`

- [ ] **Step 1: Add heartbeat-series type to authorization**

In `requestAuthorization()`, add to `typesToRead`:

```swift
HKObjectType.seriesType(forIdentifier: .heartbeat)!
```

- [ ] **Step 2: Add RR-interval extraction method**

Add after `fetchMaxHeartRate`:

```swift
private func fetchHeartbeatSeriesRRIntervals(predicate: NSPredicate) async -> [Double] {
    guard let seriesType = HKObjectType.seriesType(forIdentifier: .heartbeat) else { return [] }
    return await withCheckedContinuation { continuation in
        let query = HKSampleQuery(sampleType: seriesType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { _, samples, _ in
            guard let seriesSamples = samples as? [HKHeartbeatSeriesSample], let first = seriesSamples.first else {
                continuation.resume(returning: [])
                return
            }
            var rrIntervals: [Double] = []
            var previousTimeSeconds: TimeInterval?
            let query = HKHeartbeatSeriesQuery(heartbeatSeries: first) { _, timeSinceSampleStart, precededByGap, done, error in
                if let time = timeSinceSampleStart {
                    if let previous = previousTimeSeconds, !precededByGap {
                        let rrMs = (time - previous) * 1000.0
                        rrIntervals.append(rrMs)
                    }
                    previousTimeSeconds = time
                }
                if done {
                    continuation.resume(returning: rrIntervals)
                }
            }
            self.healthStore.execute(query)
        }
        self.healthStore.execute(query)
    }
}
```

- [ ] **Step 3: Add RMSSD fetch with SDNN fallback**

Add after the RR-interval method:

```swift
private func fetchRMSSD(predicate: NSPredicate) async -> (value: Double, isRMSSD: Bool) {
    let rrIntervals = await fetchHeartbeatSeriesRRIntervals(predicate: predicate)
    if let rmssd = HRVCalculator.rmssd(from: rrIntervals), rmssd > 0 {
        return (rmssd, true)
    }
    let sdnn = await fetchHRV(predicate: predicate)
    return (sdnn, false)
}
```

- [ ] **Step 4: Build**

Run:
```bash
xcodebuild -project ReadinessTracker.xcodeproj -scheme ReadinessTracker -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -configuration Debug build 2>&1 | tail -20
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git add ReadinessTracker/Services/HealthKitManager.swift
git commit -m "feat: fetch heartbeat series and compute RMSSD with SDNN fallback"
```

---

### Task 4: Wire RMSSD into daily data fetches

**Files:**
- Modify: `ReadinessTracker/Services/HealthKitManager.swift`

**Interfaces:**
- Consumes: `fetchRMSSD(predicate:)` returning `(value: Double, isRMSSD: Bool)`
- Produces: `DailyHealthData(hrv: ..., hrvIsRMSSD: ...)`

- [ ] **Step 1: Update `fetchTodayData()`**

Replace:
```swift
async let hrv = fetchHRV(predicate: predicate)
```

With:
```swift
async let hrvResult = fetchRMSSD(predicate: predicate)
```

Then replace the `hrv: await hrv` argument in the `DailyHealthData` initializer with:
```swift
hrv: await hrvResult.value,
hrvIsRMSSD: await hrvResult.isRMSSD,
```

- [ ] **Step 2: Update `fetchHistoricalData()`**

Replace:
```swift
async let hrv = fetchHRV(predicate: predicate)
```

With:
```swift
async let hrvResult = fetchRMSSD(predicate: predicate)
```

Then replace:
```swift
let hrvValue = await hrv
```

With:
```swift
let hrvValue = await hrvResult.value
let hrvIsRMSSDValue = await hrvResult.isRMSSD
```

And update the `DailyHealthData` initializer inside the historical loop to include:
```swift
hrv: hrvValue,
hrvIsRMSSD: hrvIsRMSSDValue,
```

- [ ] **Step 3: Build**

Run:
```bash
xcodebuild -project ReadinessTracker.xcodeproj -scheme ReadinessTracker -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -configuration Debug build 2>&1 | tail -20
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add ReadinessTracker/Services/HealthKitManager.swift
git commit -m "feat: wire RMSSD into today and historical data fetches"
```

---

### Task 5: Document RMSSD semantics in `RecoveryCalculator`

**Files:**
- Modify: `ReadinessTracker/Models/RecoveryCalculator.swift`

**Interfaces:**
- Consumes: `data.hrv` (now RMSSD when `hrvIsRMSSD == true`, otherwise SDNN)

- [ ] **Step 1: Update `scoreHRV` comment**

Change the comment inside `scoreHRV` from:
```swift
// 100 at 1.15x baseline, 75 at baseline, 0 at 0.55x baseline
```

To:
```swift
// Input is RMSSD when available, otherwise SDNN. Ratio logic is identical.
// 100 at 1.15x baseline, 75 at baseline, 0 at 0.55x baseline
```

- [ ] **Step 2: Build**

Run:
```bash
xcodebuild -project ReadinessTracker.xcodeproj -scheme ReadinessTracker -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -configuration Debug build 2>&1 | tail -20
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add ReadinessTracker/Models/RecoveryCalculator.swift
git commit -m "docs: document RMSSD semantics in recovery scoring"
```

---

### Task 6: Update UI labels for RMSSD

**Files:**
- Modify: `ReadinessTracker/Views/DashboardView.swift`
- Modify: `ReadinessTracker/Views/ReadinessScoreDetailView.swift`

**Interfaces:**
- Consumes: `data.hrvIsRMSSD`

- [ ] **Step 1: Update dashboard HRV metric card**

In `DashboardView.metricsSection`, find the HRV `MetricCard`:

```swift
MetricCard(
    title: "HRV",
    value: "\(Int(data.hrv))",
    unit: "ms",
    ...
)
```

Change `title` to:
```swift
title: data.hrvIsRMSSD ? "RMSSD" : "HRV",
```

- [ ] **Step 2: Update `ReadinessScoreDetailView` HRV label**

Open `ReadinessTracker/Views/ReadinessScoreDetailView.swift`, locate the HRV breakdown row label (likely `"HRV"`), and replace the static label with:

```swift
data.hrvIsRMSSD ? "RMSSD" : "HRV"
```

If the label is inside a `BreakdownBar` or similar component, pass the conditional string as the `label` argument.

- [ ] **Step 3: Build**

Run:
```bash
xcodebuild -project ReadinessTracker.xcodeproj -scheme ReadinessTracker -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -configuration Debug build 2>&1 | tail -20
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add ReadinessTracker/Views/DashboardView.swift ReadinessTracker/Views/ReadinessScoreDetailView.swift
git commit -m "feat: show RMSSD label when HRV is computed from heartbeat series"
```

---

### Task 7: Add recovery fallback test

**Files:**
- Modify: `ReadinessTrackerTests/RecoveryCalculatorTests.swift`

**Interfaces:**
- Consumes: `RecoveryCalculator.calculate(from:history:)` with `hrvIsRMSSD`

- [ ] **Step 1: Add RMSSD recovery test**

Open `ReadinessTrackerTests/RecoveryCalculatorTests.swift` and append:

```swift
func testRecoveryUsesRMSSDWhenFlagSet() {
    // Same HRV value as SDNN test, but flagged as RMSSD should produce identical score path.
    let data = DailyHealthData(
        date: Date(), source: .appleWatch,
        sleepHours: 8, sleepEfficiency: 0.92,
        deepSleepPercent: 0.18, remSleepPercent: 0.22,
        hrv: 70, hrvIsRMSSD: true,
        restingHeartRate: 50,
        activeCalories: 200, steps: 3000, workoutMinutes: 0
    )
    let history = [data]
    let score = RecoveryCalculator.calculate(from: data, history: history)
    XCTAssertGreaterThan(score, 80)
}
```

- [ ] **Step 2: Run tests**

Run:
```bash
xcodebuild -project ReadinessTracker.xcodeproj -scheme ReadinessTracker -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -configuration Debug test 2>&1 | tail -40
```

Expected: all tests pass, total ≥ 10.

- [ ] **Step 3: Commit**

```bash
git add ReadinessTrackerTests/RecoveryCalculatorTests.swift
git commit -m "test: verify recovery scoring accepts RMSSD flag"
```

---

### Task 8: Final verification

**Files:**
- All touched files

- [ ] **Step 1: Run full test suite**

```bash
xcodebuild -project ReadinessTracker.xcodeproj -scheme ReadinessTracker -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -configuration Debug test 2>&1 | tail -40
```

Expected: `** TEST SUCCEEDED **`

- [ ] **Step 2: Check git status**

```bash
git status --short
```

Expected: working tree clean (all changes committed).

- [ ] **Step 3: Update progress.md**

Append a new entry noting Phase 2A implementation is complete and tests pass.

---

## Self-Review

**Spec coverage:**
- `HRVCalculator` with RMSSD/SDNN → Task 1
- Heartbeat-series fetch → Task 3
- RMSSD fallback to SDNN → Task 3
- Wire into `DailyHealthData` → Task 4
- `RecoveryCalculator` semantics → Task 5
- UI label updates → Task 6
- Unit tests → Tasks 2, 7
- Full verification → Task 8

**Placeholder scan:** No TBD/TODO. All code snippets are concrete.

**Type consistency:**
- `fetchRMSSD` returns `(Double, Bool)` consistently.
- `DailyHealthData` init parameter names match existing model.
- `HRVCalculator.rmssd(from:)` takes `[Double]` and returns `Double?`.
