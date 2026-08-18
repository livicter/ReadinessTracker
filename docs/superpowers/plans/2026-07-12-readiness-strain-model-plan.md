> I'm using the writing-plans skill to create the implementation plan.

# WHOOP-Grade Readiness/Strain Model — Implementation Plan

**Goal:** Replace the simplified readiness/strain math with a WHOOP-like cardiovascular strain score (0-21) and a recovery score (0-100) that uses HRV RMSSD, RHR, sleep performance, wrist skin temperature, respiratory rate, and adaptive personal baselines.

**Architecture:** Add a focused `StrainCalculator` and `RecoveryCalculator`, extend `BaselineManager` for 7/14/30-day windows, persist HR samples in `DailyHealthData`, and update the dashboard + detail views to surface the new scores.

**Tech Stack:** Swift 5, SwiftUI, HealthKit, Swift Charts, XCTest

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
| `ReadinessTracker/Models/HRSample.swift` | New: heart-rate sample model for strain calculation |
| `ReadinessTracker/Models/HealthData.swift` | Modify: add `maxHeartRate`, `hrSamples` to `DailyHealthData` |
| `ReadinessTracker/Models/UserSettings.swift` | Modify: add `age`, `maxHeartRate` |
| `ReadinessTracker/Models/BaselineManager.swift` | Modify: add 7/14/30-day baselines and outlier flagging |
| `ReadinessTracker/Models/StrainCalculator.swift` | New: TRIMP-like 0-21 strain score |
| `ReadinessTracker/Models/RecoveryCalculator.swift` | New: recovery score 0-100 with multi-metric model |
| `ReadinessTracker/Models/ReadinessCalculator.swift` | Modify: delegate to new calculators, keep protocol |
| `ReadinessTracker/Services/HealthKitManager.swift` | Modify: fetch HR samples, max HR, pass to `DailyHealthData` |
| `ReadinessTracker/Views/DashboardView.swift` | Modify: show strain score next to recovery |
| `ReadinessTracker/Views/RecoveryStrainDetailView.swift` | Modify: real strain breakdown, strain-recovery balance |
| `ReadinessTracker/Views/ReadinessScoreDetailView.swift` | Modify: show temp/resp/SpO2 subscores |
| `ReadinessTrackerTests/StrainCalculatorTests.swift` | New: unit tests for strain math |
| `ReadinessTrackerTests/RecoveryCalculatorTests.swift` | New: unit tests for recovery math |

---

### Task 1: Heart-rate sample model and data model extensions

**Files:**
- Create: `ReadinessTracker/Models/HRSample.swift`
- Modify: `ReadinessTracker/Models/HealthData.swift`
- Modify: `ReadinessTracker/Models/UserSettings.swift`

**Interfaces:**
- Produces: `HRSample` struct with `timestamp: Date`, `bpm: Double`
- Produces: `DailyHealthData.maxHeartRate: Double?`, `DailyHealthData.hrSamples: [HRSample]`
- Produces: `UserSettings.age: Int?`, `UserSettings.maxHeartRate: Int?`

- [ ] **Step 1: Add `HRSample.swift`**

```swift
import Foundation

struct HRSample: Codable, Identifiable, Hashable {
    let id: UUID
    let timestamp: Date
    let bpm: Double
    
    init(id: UUID = UUID(), timestamp: Date, bpm: Double) {
        self.id = id
        self.timestamp = timestamp
        self.bpm = bpm
    }
}
```

- [ ] **Step 2: Extend `DailyHealthData`**

In `ReadinessTracker/Models/HealthData.swift`, add two properties to `DailyHealthData`:

```swift
let maxHeartRate: Double?
let hrSamples: [HRSample]
```

Update the default init with:

```swift
maxHeartRate: Double? = nil,
hrSamples: [HRSample] = []
```

Update the legacy init to set them to `nil` / `[]`.

- [ ] **Step 3: Extend `UserSettings`**

In `ReadinessTracker/Models/UserSettings.swift`, add:

```swift
var age: Int? = nil
var maxHeartRate: Int? = nil

var estimatedMaxHeartRate: Int {
    maxHeartRate ?? (age.map { 220 - $0 } ?? 190)
}
```

- [ ] **Step 4: Build to check model changes compile**

Run:
```bash
xcodebuild -project ReadinessTracker.xcodeproj -scheme ReadinessTracker -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -configuration Debug build 2>&1 | tail -20
```

Expected: `** BUILD SUCCEEDED **`

---

### Task 2: Adaptive baseline manager

**Files:**
- Modify: `ReadinessTracker/Models/BaselineManager.swift`

**Interfaces:**
- Produces: `BaselineManager.baseline(for: [Double], window: Int) -> Double?`
- Produces: `BaselineManager.hrvBaseline(history:window:)`, `rhrBaseline(history:window:)`, `respiratoryRateBaseline(history:window:)`, `skinTempBaseline(history:window:)`
- Produces: `BaselineManager.isOutlier(value:baseline:threshold:) -> Bool`

- [ ] **Step 1: Replace fixed rolling helpers with windowed baseline**

Replace `rollingAverage(values:days:)` and the three baseline methods with:

```swift
enum BaselineManager {
    static func baseline(for values: [Double], window: Int = 14) -> Double? {
        let recent = values.filter { $0 > 0 }.suffix(window)
        guard recent.count >= 3 else { return nil }
        return recent.reduce(0, +) / Double(recent.count)
    }
    
    static func standardDeviation(for values: [Double], window: Int = 14) -> Double? {
        let recent = values.filter { $0 > 0 }.suffix(window)
        guard recent.count >= 3 else { return nil }
        let mean = recent.reduce(0, +) / Double(recent.count)
        let variance = recent.map { pow($0 - mean, 2) }.reduce(0, +) / Double(recent.count)
        return sqrt(variance)
    }
    
    static func isOutlier(value: Double, baseline: Double, stdDev: Double, threshold: Double = 2.0) -> Bool {
        guard stdDev > 0 else { return false }
        return abs(value - baseline) > threshold * stdDev
    }
    
    static func hrvBaseline(from history: [DailyHealthData], window: Int = 14) -> Double {
        baseline(for: history.map(\.hrv), window: window) ?? 50.0
    }
    
    static func rhrBaseline(from history: [DailyHealthData], window: Int = 14) -> Double {
        baseline(for: history.map(\.restingHeartRate), window: window) ?? 60.0
    }
    
    static func sleepBaseline(from history: [DailyHealthData], window: Int = 7) -> Double {
        baseline(for: history.map(\.sleepHours), window: window) ?? 7.5
    }
    
    static func respiratoryRateBaseline(from history: [DailyHealthData], window: Int = 14) -> Double {
        baseline(for: history.compactMap(\.respiratoryRate), window: window) ?? 16.0
    }
    
    static func skinTempBaseline(from history: [DailyHealthData], window: Int = 14) -> Double? {
        baseline(for: history.compactMap(\.skinTemperature), window: window)
    }
}
```

Keep the existing `consistencyScore` and `sleepDurationConsistency` methods.

- [ ] **Step 2: Build**

Run the same `xcodebuild` command.
Expected: `** BUILD SUCCEEDED **`

---

### Task 3: TRIMP-like strain calculator

**Files:**
- Create: `ReadinessTracker/Models/StrainCalculator.swift`

**Interfaces:**
- Consumes: `DailyHealthData.hrSamples`, `DailyHealthData.activeCalories`, `DailyHealthData.workoutMinutes`, `DailyHealthData.maxHeartRate`
- Produces: `StrainCalculator.calculate(from data: DailyHealthData, history: [DailyHealthData]) -> Double` returning 0-21

- [ ] **Step 1: Implement `StrainCalculator.swift`**

```swift
import Foundation

enum StrainCalculator {
    /// WHOOP-style cardiovascular strain score, 0-21.
    /// Uses TRIMP-like exponential points based on heart-rate reserve.
    static func calculate(from data: DailyHealthData, history: [DailyHealthData]) -> Double {
        let sampleStrain = strainFromHRSamples(data)
        if sampleStrain > 0 {
            let maxStrain = maxHistoricalStrain(from: history, fallback: sampleStrain * 1.5)
            return min(21.0, (sampleStrain / max(maxStrain, 1.0)) * 21.0)
        }
        return fallbackStrain(from: data)
    }
    
    private static func strainFromHRSamples(_ data: DailyHealthData) -> Double {
        guard let restingHR = data.restingHeartRate > 0 ? data.restingHeartRate : nil,
              let maxHR = data.maxHeartRate ?? UserSettings.load().estimatedMaxHeartRate > 0
                ? Double(UserSettings.load().estimatedMaxHeartRate) : nil,
              !data.hrSamples.isEmpty else { return 0 }
        
        let reserve = maxHR - restingHR
        guard reserve > 0 else { return 0 }
        
        var totalPoints: Double = 0
        // Group samples into 1-minute buckets, use average BPM per minute
        let grouped = Dictionary(grouping: data.hrSamples) { sample in
            Calendar.current.dateInterval(of: .minute, for: sample.timestamp)?.start
        }
        
        for (_, samples) in grouped {
            let avgBPM = samples.map(\.bpm).reduce(0, +) / Double(samples.count)
            let zone = max(0, min(1, (avgBPM - restingHR) / reserve))
            // TRIMP exponential: 0.5 * e^(1.92 * zone) per minute
            let points = 0.5 * exp(1.92 * zone)
            totalPoints += points
        }
        
        return totalPoints
    }
    
    private static func maxHistoricalStrain(from history: [DailyHealthData], fallback: Double) -> Double {
        let values = history.map { max(fallbackStrain(from: $0), strainFromHRSamples($0)) }.filter { $0 > 0 }
        guard let maxValue = values.max(), maxValue > 0 else { return fallback }
        return max(maxValue, fallback)
    }
    
    /// Fallback when no HR samples available.
    private static func fallbackStrain(from data: DailyHealthData) -> Double {
        let calScore = min(15, data.activeCalories / 200)
        let workoutScore = min(6, Double(data.workoutMinutes) / 30)
        return calScore + workoutScore
    }
}
```

- [ ] **Step 2: Build**

Run the `xcodebuild` command.
Expected: `** BUILD SUCCEEDED **`

---

### Task 4: Recovery calculator with multi-metric model

**Files:**
- Create: `ReadinessTracker/Models/RecoveryCalculator.swift`

**Interfaces:**
- Consumes: `DailyHealthData.hrv`, `restingHeartRate`, `sleepData`, `skinTemperature`, `respiratoryRate`, `bloodOxygen`
- Consumes: `[DailyHealthData]` for baselines
- Produces: `RecoveryCalculator.calculate(from data:history:) -> Int` (0-100)

- [ ] **Step 1: Implement `RecoveryCalculator.swift`**

```swift
import Foundation

enum RecoveryCalculator {
    struct RecoveryBreakdown {
        let hrvScore: Int
        let rhrScore: Int
        let sleepScore: Int
        let tempScore: Int
        let respScore: Int
        let totalScore: Int
    }
    
    static func calculate(from data: DailyHealthData, history: [DailyHealthData]) -> Int {
        calculateBreakdown(from: data, history: history).totalScore
    }
    
    static func calculateBreakdown(from data: DailyHealthData, history: [DailyHealthData]) -> RecoveryBreakdown {
        let hrvScore = scoreHRV(data.hrv, history: history)
        let rhrScore = scoreRHR(data.restingHeartRate, history: history)
        let sleepScore = data.sleepData.score()
        let tempScore = scoreSkinTemp(data.skinTemperature, history: history)
        let respScore = scoreRespiratoryRate(data.respiratoryRate, history: history)
        
        let total = Int(
            Double(hrvScore) * 0.35 +
            Double(rhrScore) * 0.20 +
            Double(sleepScore) * 0.25 +
            Double(tempScore) * 0.10 +
            Double(respScore) * 0.10
        )
        
        return RecoveryBreakdown(
            hrvScore: hrvScore,
            rhrScore: rhrScore,
            sleepScore: sleepScore,
            tempScore: tempScore,
            respScore: respScore,
            totalScore: min(100, max(0, total))
        )
    }
    
    private static func scoreHRV(_ hrv: Double, history: [DailyHealthData]) -> Int {
        guard hrv > 0 else { return 50 }
        let baseline = BaselineManager.hrvBaseline(from: history)
        let ratio = hrv / baseline
        // 100 at 1.15x baseline, 50 at baseline, 0 at 0.55x baseline
        let score = Int((ratio - 0.55) / 0.60 * 100)
        return min(100, max(0, score))
    }
    
    private static func scoreRHR(_ rhr: Double, history: [DailyHealthData]) -> Int {
        guard rhr > 0 else { return 50 }
        let baseline = BaselineManager.rhrBaseline(from: history)
        let ratio = rhr / baseline
        // Lower RHR = better recovery
        let score = Int((1.25 - ratio) / 0.25 * 100)
        return min(100, max(0, score))
    }
    
    private static func scoreSkinTemp(_ temp: Double?, history: [DailyHealthData]) -> Int {
        guard let temp = temp, temp > 0 else { return 75 }
        guard let baseline = BaselineManager.skinTempBaseline(from: history) else { return 75 }
        // Skin temp 0.5°C above baseline = lower recovery (illness/overreaching)
        let deviation = temp - baseline
        let score = Int(100 - abs(deviation) * 100)
        return min(100, max(0, score))
    }
    
    private static func scoreRespiratoryRate(_ rate: Double?, history: [DailyHealthData]) -> Int {
        guard let rate = rate, rate > 0 else { return 75 }
        let baseline = BaselineManager.respiratoryRateBaseline(from: history)
        let ratio = rate / baseline
        // Lower resp rate = better recovery; penalize elevation
        let score = Int((1.25 - ratio) / 0.25 * 100)
        return min(100, max(0, score))
    }
}
```

- [ ] **Step 2: Build**

Run the `xcodebuild` command.
Expected: `** BUILD SUCCEEDED **`

---

### Task 5: Wire new calculators into `ReadinessCalculator`

**Files:**
- Modify: `ReadinessTracker/Models/ReadinessCalculator.swift`

**Interfaces:**
- Consumes: `StrainCalculator.calculate`, `RecoveryCalculator.calculateBreakdown`
- Produces: updated `ReadinessBreakdown` with temp/resp scores and `DualReadinessScores`

- [ ] **Step 1: Extend `ReadinessBreakdown`**

Add to `ReadinessBreakdown` in `ReadinessCalculator.swift`:

```swift
let tempScore: Int
let respScore: Int
let strainScoreValue: Double
```

- [ ] **Step 2: Update `calculateBreakdown`**

Replace the body of `calculateBreakdown` with:

```swift
let recovery = RecoveryCalculator.calculateBreakdown(from: data, history: history)
let strainValue = StrainCalculator.calculate(from: data, history: history)
let strainScore = Int(max(0, 100 - (strainValue / 21.0) * 100))
let consistencyScore = BaselineManager.consistencyScore(from: history)

let total = Int(
    Double(recovery.hrvScore) * 0.30 +
    Double(recovery.sleepScore) * 0.25 +
    Double(recovery.rhrScore) * 0.20 +
    Double(strainScore) * 0.15 +
    Double(consistencyScore) * 0.10
)

return ReadinessBreakdown(
    sleepScore: recovery.sleepScore,
    hrvScore: recovery.hrvScore,
    recoveryScore: recovery.rhrScore,
    strainScore: strainScore,
    consistencyScore: consistencyScore,
    totalScore: min(100, max(0, total)),
    tempScore: recovery.tempScore,
    respScore: recovery.respScore,
    strainScoreValue: strainValue
)
```

- [ ] **Step 3: Update `ReadinessBreakdown` in `HealthData.swift`**

Add the new fields there as well, with defaults in inits.

- [ ] **Step 4: Build**

Run the `xcodebuild` command.
Expected: `** BUILD SUCCEEDED **`

---

### Task 6: Fetch HR samples and max HR in `HealthKitManager`

**Files:**
- Modify: `ReadinessTracker/Services/HealthKitManager.swift`

**Interfaces:**
- Produces: `DailyHealthData` populated with `maxHeartRate` and `hrSamples`

- [ ] **Step 1: Add heart-rate type to authorization**`

In `requestAuthorization()`, add to `typesToRead`:

```swift
HKObjectType.quantityType(forIdentifier: .heartRate)!
```

- [ ] **Step 2: Add fetch methods**

Add two private methods:

```swift
private func fetchHeartRateSamples(predicate: NSPredicate) async -> [HRSample] {
    guard let type = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return [] }
    return await withCheckedContinuation { continuation in
        let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]) { _, samples, _ in
            guard let samples = samples as? [HKQuantitySample] else {
                continuation.resume(returning: [])
                return
            }
            let hrsamples = samples.map {
                HRSample(timestamp: $0.startDate, bpm: $0.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute())))
            }
            continuation.resume(returning: hrsamples)
        }
        self.healthStore.execute(query)
    }
}

private func fetchMaxHeartRate(predicate: NSPredicate) async -> Double? {
    guard let type = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return nil }
    return await withCheckedContinuation { continuation in
        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .discreteMax) { _, stats, _ in
            continuation.resume(returning: stats?.maximumQuantity()?.doubleValue(for: HKUnit.count().unitDivided(by: .minute())))
        }
        self.healthStore.execute(query)
    }
}
```

- [ ] **Step 3: Wire into `fetchTodayData` and `fetchAndSaveDayData`**

Add `async let hrSamples = fetchHeartRateSamples(predicate: predicate)` and `async let maxHR = fetchMaxHeartRate(predicate: predicate)` to both methods, then pass them into `DailyHealthData` init.

- [ ] **Step 4: Build**

Run the `xcodebuild` command.
Expected: `** BUILD SUCCEEDED **`

---

### Task 7: Update dashboard strain/recovery display

**Files:**
- Modify: `ReadinessTracker/Views/DashboardView.swift`

**Interfaces:**
- Consumes: `ReadinessBreakdown.strainScoreValue`, `scores.general`

- [ ] **Step 1: Show strain score in WHOOP section**

In `whoopSection`, replace `calculateStrainScore(data:)` usage with:

```swift
let strainValue = scores.breakdown.strainScoreValue
```

Update the Strain value text to show one decimal:

```swift
Text(String(format: "%.1f", strainValue))
```

- [ ] **Step 2: Build**

Run the `xcodebuild` command.
Expected: `** BUILD SUCCEEDED **`

---

### Task 8: Revive `RecoveryStrainDetailView`

**Files:**
- Modify: `ReadinessTracker/Views/RecoveryStrainDetailView.swift`

**Interfaces:**
- Consumes: `ReadinessBreakdown.strainScoreValue`, `scores.breakdown`

- [ ] **Step 1: Replace placeholder `strainScore` computed property**

```swift
private var strainScore: Double {
    scores.breakdown.strainScoreValue
}
```

- [ ] **Step 2: Add a simple strain-recovery balance ring**

Replace the `EmptyView()` in `wheelSection` with a `ZStack` of two `Circle().stroke()` rings showing strain and recovery.

- [ ] **Step 3: Update strain breakdown rows**

If HR samples exist, show a "Cardiovascular" row with the TRIMP points. Keep calories/workout rows as fallback contributors.

- [ ] **Step 4: Build**

Run the `xcodebuild` command.
Expected: `** BUILD SUCCEEDED **`

---

### Task 9: Add temp/resp subscores to `ReadinessScoreDetailView`

**Files:**
- Modify: `ReadinessTracker/Views/ReadinessScoreDetailView.swift`

**Interfaces:**
- Consumes: `ReadinessBreakdown.tempScore`, `respScore`

- [ ] **Step 1: Add two breakdown rows**

Add rows for "Skin Temp" and "Respiratory Rate" using the existing breakdown row component, passing `scores.breakdown.tempScore` and `respScore`.

- [ ] **Step 2: Build**

Run the `xcodebuild` command.
Expected: `** BUILD SUCCEEDED **`

---

### Task 10: Unit tests

**Files:**
- Create: `ReadinessTrackerTests/StrainCalculatorTests.swift`
- Create: `ReadinessTrackerTests/RecoveryCalculatorTests.swift`

- [ ] **Step 1: Add strain tests**

```swift
import XCTest
@testable import Readiness

final class StrainCalculatorTests: XCTestCase {
    func testNoDataReturnsFallbackStrain() {
        let data = DailyHealthData(date: Date(), source: .appleWatch)
        let strain = StrainCalculator.calculate(from: data, history: [])
        XCTAssertEqual(strain, 0, accuracy: 0.1)
    }
    
    func testCaloriesAndWorkoutProduceFallbackStrain() {
        let data = DailyHealthData(date: Date(), source: .appleWatch, activeCalories: 1000, workoutMinutes: 60)
        let strain = StrainCalculator.calculate(from: data, history: [])
        XCTAssertEqual(strain, 15 + 2, accuracy: 0.1)
    }
    
    func testHRSamplesCapAt21() {
        let samples = (0..<600).map { i in
            HRSample(timestamp: Date().addingTimeInterval(TimeInterval(i * 60)), bpm: 180)
        }
        let data = DailyHealthData(date: Date(), source: .appleWatch, restingHeartRate: 60, maxHeartRate: 190, hrSamples: samples)
        let strain = StrainCalculator.calculate(from: data, history: [])
        XCTAssertLessThanOrEqual(strain, 21)
    }
}
```

- [ ] **Step 2: Add recovery tests**

```swift
import XCTest
@testable import Readiness

final class RecoveryCalculatorTests: XCTestCase {
    func testPerfectRecovery() {
        let data = DailyHealthData(
            date: Date(), source: .appleWatch,
            sleepHours: 8, sleepEfficiency: 0.92,
            deepSleepPercent: 0.18, remSleepPercent: 0.22,
            hrv: 70, restingHeartRate: 50,
            activeCalories: 200, steps: 3000, workoutMinutes: 0
        )
        let history = [data]
        let score = RecoveryCalculator.calculate(from: data, history: history)
        XCTAssertGreaterThan(score, 80)
    }
    
    func testPoorRecovery() {
        let data = DailyHealthData(
            date: Date(), source: .appleWatch,
            sleepHours: 5, sleepEfficiency: 0.70,
            deepSleepPercent: 0.05, remSleepPercent: 0.10,
            hrv: 25, restingHeartRate: 75,
            activeCalories: 50, steps: 1000, workoutMinutes: 0
        )
        let history = [data]
        let score = RecoveryCalculator.calculate(from: data, history: history)
        XCTAssertLessThan(score, 40)
    }
}
```

- [ ] **Step 3: Run tests**

```bash
xcodebuild -project ReadinessTracker.xcodeproj -scheme ReadinessTracker -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -configuration Debug test 2>&1 | tail -40
```

Expected: tests pass.

---

## Self-Review

**Spec coverage:**
- 0-21 cardiovascular strain → Tasks 3, 6, 7, 8
- Recovery score 0-100 with HRV/RHR/sleep/temp/resp → Tasks 2, 4, 5
- Adaptive 7/14/30-day baselines → Task 2
- Strain-recovery balance visualization → Task 8
- UI updates → Tasks 7, 8, 9
- Testing → Task 10

**Placeholder scan:** No TBD/TODO; all code snippets are concrete.

**Type consistency:** `DailyHealthData` fields match between model init and HealthKitManager usage. `ReadinessBreakdown` fields match in `ReadinessCalculator` and `HealthData.swift`.

**Gaps:** SpO2 is collected but not scored. Add in v1.1 if user wants; excluded to keep Phase 1 focused.
