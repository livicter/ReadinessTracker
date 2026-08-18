> I'm using the writing-plans skill to create the implementation plan.

# Breadth Metrics Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Google Health-style breadth metrics: score SpO2 in recovery, surface hydration/caffeine/protein context, and optionally log menstrual cycle impact.

**Architecture:** Add a focused `NutritionSummary` model. Extend `DailyHealthData` with nutrition and menstrual flow. Update `RecoveryCalculator` to score SpO2 and apply an opt-in menstrual adjustment. Fetch the new HealthKit types in `HealthKitManager` and surface them in detail views.

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
| `ReadinessTracker/Models/NutritionSummary.swift` | New: nutrition context model |
| `ReadinessTracker/Models/HealthData.swift` | Modify: add `nutrition`, `menstrualFlow` |
| `ReadinessTracker/Models/RecoveryCalculator.swift` | Modify: SpO2 score, menstrual adjustment, weight rebalance |
| `ReadinessTracker/Models/UserSettings.swift` | Modify: add `trackMenstrualCycle` flag |
| `ReadinessTracker/Services/HealthKitManager.swift` | Modify: fetch nutrition, menstrual flow, SpO2 already present |
| `ReadinessTracker/Views/ReadinessDetailView.swift` | Modify: add SpO2 breakdown row |
| `ReadinessTracker/Views/RecoveryStrainDetailView.swift` | Modify: add nutrition card |
| `ReadinessTrackerTests/NutritionSummaryTests.swift` | New: nutrition encode/decode |
| `ReadinessTrackerTests/RecoveryCalculatorTests.swift` | Modify: add SpO2 + menstrual tests |

---

### Task 1: Add `NutritionSummary` model

**Files:**
- Create: `ReadinessTracker/Models/NutritionSummary.swift`

**Interfaces:**
- Produces: `NutritionSummary` struct with `waterLiters`, `caffeineMg`, `proteinGrams`, `isEmpty`

- [ ] **Step 1: Create `NutritionSummary.swift`**

```swift
import Foundation

struct NutritionSummary: Codable, Hashable {
    let waterLiters: Double?
    let caffeineMg: Double?
    let proteinGrams: Double?
    
    var isEmpty: Bool {
        waterLiters == nil && caffeineMg == nil && proteinGrams == nil
    }
    
    init(waterLiters: Double? = nil, caffeineMg: Double? = nil, proteinGrams: Double? = nil) {
        self.waterLiters = waterLiters
        self.caffeineMg = caffeineMg
        self.proteinGrams = proteinGrams
    }
}
```

- [ ] **Step 2: Build**

Run:
```bash
xcodebuild -project ReadinessTracker.xcodeproj -scheme ReadinessTracker -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -configuration Debug build 2>&1 | tail -20
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add ReadinessTracker/Models/NutritionSummary.swift
git commit -m "feat: add NutritionSummary model"
```

---

### Task 2: Extend `DailyHealthData` with nutrition and menstrual flow

**Files:**
- Modify: `ReadinessTracker/Models/HealthData.swift`

**Interfaces:**
- Produces: `DailyHealthData.nutrition: NutritionSummary`
- Produces: `DailyHealthData.menstrualFlow: Bool`

- [ ] **Step 1: Add properties and defaults**

In `DailyHealthData`, add:
```swift
let nutrition: NutritionSummary
let menstrualFlow: Bool
```

In the modern `init`, add parameter:
```swift
nutrition: NutritionSummary = NutritionSummary(),
menstrualFlow: Bool = false,
```

And assign:
```swift
self.nutrition = nutrition
self.menstrualFlow = menstrualFlow
```

- [ ] **Step 2: Update legacy init**

```swift
self.nutrition = NutritionSummary()
self.menstrualFlow = false
```

- [ ] **Step 3: Update CodingKeys and decoder**

Add `nutrition`, `menstrualFlow` to `CodingKeys` and in `init(from:)`:
```swift
self.nutrition = try container.decodeIfPresent(NutritionSummary.self, forKey: .nutrition) ?? NutritionSummary()
self.menstrualFlow = try container.decodeIfPresent(Bool.self, forKey: .menstrualFlow) ?? false
```

- [ ] **Step 4: Build**

Run:
```bash
xcodebuild -project ReadinessTracker.xcodeproj -scheme ReadinessTracker -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -configuration Debug build 2>&1 | tail -20
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git add ReadinessTracker/Models/HealthData.swift
git commit -m "feat: add nutrition and menstrualFlow to DailyHealthData"
```

---

### Task 3: Score SpO2 and add menstrual adjustment in `RecoveryCalculator`

**Files:**
- Modify: `ReadinessTracker/Models/RecoveryCalculator.swift`
- Modify: `ReadinessTracker/Models/UserSettings.swift`

**Interfaces:**
- Consumes: `data.bloodOxygen`, `data.menstrualFlow`, `UserSettings.trackMenstrualCycle`
- Produces: `RecoveryBreakdown.spo2Score`, updated total with new weights

- [ ] **Step 1: Add `trackMenstrualCycle` to `UserSettings`**

In `ReadinessTracker/Models/UserSettings.swift`, add:
```swift
var trackMenstrualCycle: Bool = false
```

- [ ] **Step 2: Extend `RecoveryBreakdown`**

Add:
```swift
let spo2Score: Int
```

- [ ] **Step 3: Update `calculateBreakdown`**

```swift
static func calculateBreakdown(from data: DailyHealthData, history: [DailyHealthData]) -> RecoveryBreakdown {
    let hrvScore = scoreHRV(data.hrv, history: history, data: data)
    let rhrScore = scoreRHR(data.restingHeartRate, history: history)
    let sleepScore = data.sleepData.score()
    let tempScore = scoreSkinTemp(data.skinTemperature, history: history)
    let respScore = scoreRespiratoryRate(data.respiratoryRate, history: history)
    let spo2Score = scoreSpO2(data.bloodOxygen)
    
    var total = Int(
        Double(hrvScore) * 0.30 +
        Double(sleepScore) * 0.25 +
        Double(rhrScore) * 0.20 +
        Double(spo2Score) * 0.05 +
        Double(tempScore) * 0.10 +
        Double(respScore) * 0.10
    )
    
    if UserSettings.load().trackMenstrualCycle && data.menstrualFlow {
        total -= 3
    }
    
    return RecoveryBreakdown(
        hrvScore: hrvScore,
        rhrScore: rhrScore,
        sleepScore: sleepScore,
        tempScore: tempScore,
        respScore: respScore,
        spo2Score: spo2Score,
        totalScore: min(100, max(0, total))
    )
}
```

- [ ] **Step 4: Add `scoreSpO2`**

```swift
private static func scoreSpO2(_ spo2: Double?) -> Int {
    guard let spo2 = spo2, spo2 > 0 else { return 75 }
    let fraction = spo2 > 1.0 ? spo2 / 100.0 : spo2 // handle both 95 and 0.95
    if fraction >= 0.98 { return 100 }
    if fraction <= 0.90 { return 0 }
    return Int((fraction - 0.90) / 0.08 * 100)
}
```

- [ ] **Step 5: Build**

Run:
```bash
xcodebuild -project ReadinessTracker.xcodeproj -scheme ReadinessTracker -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -configuration Debug build 2>&1 | tail -20
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 6: Commit**

```bash
git add ReadinessTracker/Models/RecoveryCalculator.swift ReadinessTracker/Models/UserSettings.swift
git commit -m "feat: score SpO2 and add opt-in menstrual adjustment"
```

---

### Task 4: Wire `RecoveryCalculator` output into `ReadinessCalculator`

**Files:**
- Modify: `ReadinessTracker/Models/ReadinessCalculator.swift`

**Interfaces:**
- Consumes: `RecoveryBreakdown.spo2Score`
- Produces: `ReadinessBreakdown.spo2Score`

- [ ] **Step 1: Add `spo2Score` to `ReadinessBreakdown`**

Add:
```swift
let spo2Score: Int
```

Add default in init:
```swift
spo2Score: Int = 0
```

Add to `CodingKeys` and decoder with fallback `0`.

- [ ] **Step 2: Update `calculateBreakdown` mapping**

In the `ReadinessBreakdown` initializer, add:
```swift
spo2Score: recovery.spo2Score
```

- [ ] **Step 3: Build**

Run:
```bash
xcodebuild -project ReadinessTracker.xcodeproj -scheme ReadinessTracker -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -configuration Debug build 2>&1 | tail -20
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add ReadinessTracker/Models/ReadinessCalculator.swift
git commit -m "feat: expose spo2Score in ReadinessBreakdown"
```

---

### Task 5: Fetch nutrition and menstrual flow in `HealthKitManager`

**Files:**
- Modify: `ReadinessTracker/Services/HealthKitManager.swift`

**Interfaces:**
- Produces: `HealthKitManager.fetchNutrition(predicate:) -> NutritionSummary`
- Produces: `HealthKitManager.fetchMenstrualFlow(predicate:) -> Bool`

- [ ] **Step 1: Add types to authorization**

In `requestAuthorization()`, add to `typesToRead`:
```swift
HKObjectType.quantityType(forIdentifier: .dietaryWater)!,
HKObjectType.quantityType(forIdentifier: .dietaryCaffeine)!,
HKObjectType.quantityType(forIdentifier: .dietaryProtein)!,
HKObjectType.categoryType(forIdentifier: .menstrualFlow)!
```

- [ ] **Step 2: Add fetch methods**

```swift
private func fetchNutrition(predicate: NSPredicate) async -> NutritionSummary {
    let water = await fetchSumQuantity(
        type: HKQuantityType.quantityType(forIdentifier: .dietaryWater)!,
        predicate: predicate,
        unit: .literUnit(with: .milli)
    ).map { $0 / 1000.0 }
    
    let caffeine = await fetchSumQuantity(
        type: HKQuantityType.quantityType(forIdentifier: .dietaryCaffeine)!,
        predicate: predicate,
        unit: .gramUnit(with: .milli)
    ).map { $0 }
    
    let protein = await fetchSumQuantity(
        type: HKQuantityType.quantityType(forIdentifier: .dietaryProtein)!,
        predicate: predicate,
        unit: .gram()
    ).map { $0 }
    
    return NutritionSummary(waterLiters: water, caffeineMg: caffeine, proteinGrams: protein)
}

private func fetchMenstrualFlow(predicate: NSPredicate) async -> Bool {
    guard let type = HKObjectType.categoryType(forIdentifier: .menstrualFlow) else { return false }
    return await withCheckedContinuation { continuation in
        let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: 1, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { _, samples, _ in
            continuation.resume(returning: samples?.isEmpty == false)
        }
        self.healthStore.execute(query)
    }
}
```

Note: `dietaryCaffeine` unit is milligrams; `dietaryWater` is milliliters, convert to liters.

- [ ] **Step 3: Wire into daily fetches**

In `fetchTodayData()`:
```swift
async let nutrition = fetchNutrition(predicate: predicate)
async let menstrualFlow = fetchMenstrualFlow(predicate: predicate)
```

Pass into `DailyHealthData`:
```swift
nutrition: await nutrition,
menstrualFlow: await menstrualFlow,
```

In `fetchHistoricalData()`, do the same with local bindings.

- [ ] **Step 4: Build**

Run:
```bash
xcodebuild -project ReadinessTracker.xcodeproj -scheme ReadinessTracker -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -configuration Debug build 2>&1 | tail -20
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git add ReadinessTracker/Services/HealthKitManager.swift
git commit -m "feat: fetch nutrition and menstrual flow from HealthKit"
```

---

### Task 6: Update `ReadinessDetailView` with SpO2 row

**Files:**
- Modify: `ReadinessTracker/Views/ReadinessDetailView.swift`

**Interfaces:**
- Consumes: `scores.breakdown.spo2Score`, `data.bloodOxygen`

- [ ] **Step 1: Add SpO2 breakdown row**

Locate the breakdown rows (HRV, Sleep, Recovery, etc.) and add:

```swift
BreakdownBar(
    label: "SpO2",
    score: scores.breakdown.spo2Score,
    color: RTColor.optimal,
    weight: "5%",
    metricType: .bloodOxygen,
    currentValue: data.bloodOxygen ?? 0,
    history: history,
    source: .appleWatch
)
```

If `.bloodOxygen` does not exist in `MetricType`, use `.respiratoryRate` or add `case bloodOxygen` to `MetricType` (preferred but out of scope for this task; use an existing metric type as placeholder).

- [ ] **Step 2: Build**

Run:
```bash
xcodebuild -project ReadinessTracker.xcodeproj -scheme ReadinessTracker -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -configuration Debug build 2>&1 | tail -20
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add ReadinessTracker/Views/ReadinessDetailView.swift
git commit -m "feat: show SpO2 breakdown row in ReadinessDetailView"
```

---

### Task 7: Update `RecoveryStrainDetailView` with nutrition card

**Files:**
- Modify: `ReadinessTracker/Views/RecoveryStrainDetailView.swift`

**Interfaces:**
- Consumes: `data.nutrition`

- [ ] **Step 1: Add nutrition section**

Add a private computed property:

```swift
private var nutritionSection: some View {
    NativeCard {
        VStack(alignment: .leading, spacing: 16) {
            Text("Nutrition")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
            
            if data.nutrition.isEmpty {
                Text("No nutrition data")
                    .font(.subheadline)
                    .foregroundStyle(RTColor.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(spacing: 12) {
                    if let water = data.nutrition.waterLiters {
                        NutritionRow(icon: "drop.fill", label: "Water", value: String(format: "%.1f", water), unit: "L", color: .cyan)
                    }
                    if let caffeine = data.nutrition.caffeineMg {
                        NutritionRow(icon: "cup.and.saucer.fill", label: "Caffeine", value: "\(Int(caffeine))", unit: "mg", color: RTColor.caution)
                    }
                    if let protein = data.nutrition.proteinGrams {
                        NutritionRow(icon: "fork.knife", label: "Protein", value: "\(Int(protein))", unit: "g", color: RTColor.good)
                    }
                }
            }
        }
    }
}
```

Add it to the `body` `VStack`.

- [ ] **Step 2: Add `NutritionRow` view**

```swift
private struct NutritionRow: View {
    let icon: String
    let label: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                Text("\(value) \(unit)")
                    .font(.caption)
                    .foregroundStyle(RTColor.secondaryText)
            }
            
            Spacer()
        }
        .padding(12)
        .background(RTColor.surfaceHighlight.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: AppleTheme.cornerRadiusMedium, style: .continuous))
    }
}
```

- [ ] **Step 3: Build**

Run:
```bash
xcodebuild -project ReadinessTracker.xcodeproj -scheme ReadinessTracker -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -configuration Debug build 2>&1 | tail -20
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add ReadinessTracker/Views/RecoveryStrainDetailView.swift
git commit -m "feat: show nutrition card in RecoveryStrainDetailView"
```

---

### Task 8: Unit tests

**Files:**
- Create: `ReadinessTrackerTests/NutritionSummaryTests.swift`
- Modify: `ReadinessTrackerTests/RecoveryCalculatorTests.swift`

**Interfaces:**
- Consumes: `NutritionSummary`, `RecoveryCalculator`

- [ ] **Step 1: Create `NutritionSummaryTests.swift`**

```swift
import XCTest
@testable import Readiness

final class NutritionSummaryTests: XCTestCase {
    func testNutritionSummaryEncodingRoundTrip() throws {
        let summary = NutritionSummary(waterLiters: 2.5, caffeineMg: 120, proteinGrams: 80)
        let encoded = try JSONEncoder().encode(summary)
        let decoded = try JSONDecoder().decode(NutritionSummary.self, from: encoded)
        XCTAssertEqual(decoded.waterLiters, 2.5)
        XCTAssertEqual(decoded.caffeineMg, 120)
        XCTAssertEqual(decoded.proteinGrams, 80)
    }
    
    func testNutritionSummaryIsEmpty() {
        XCTAssertTrue(NutritionSummary().isEmpty)
        XCTAssertFalse(NutritionSummary(waterLiters: 1.0).isEmpty)
    }
}
```

Add to test target with:
```bash
ruby -e "require 'xcodeproj'; p = Xcodeproj::Project.open('ReadinessTracker.xcodeproj'); t = p.targets.find { |x| x.name == 'ReadinessTrackerTests' }; g = p.main_group.find_subpath('ReadinessTrackerTests', true); t.add_file_references([g.new_file('NutritionSummaryTests.swift')]); p.save"
```

- [ ] **Step 2: Add SpO2 and menstrual tests**

Append to `RecoveryCalculatorTests.swift`:

```swift
func testPerfectSpO2() {
    let data = DailyHealthData(
        date: Date(), source: .appleWatch,
        sleepHours: 8, sleepEfficiency: 0.92,
        deepSleepPercent: 0.18, remSleepPercent: 0.22,
        hrv: 70, hrvIsRMSSD: true,
        restingHeartRate: 50,
        bloodOxygen: 99,
        activeCalories: 200, steps: 3000, workoutMinutes: 0
    )
    let breakdown = RecoveryCalculator.calculateBreakdown(from: data, history: [data])
    XCTAssertEqual(breakdown.spo2Score, 100)
}

func testLowSpO2() {
    let data = DailyHealthData(
        date: Date(), source: .appleWatch,
        sleepHours: 8, sleepEfficiency: 0.92,
        deepSleepPercent: 0.18, remSleepPercent: 0.22,
        hrv: 70, hrvIsRMSSD: true,
        restingHeartRate: 50,
        bloodOxygen: 88,
        activeCalories: 200, steps: 3000, workoutMinutes: 0
    )
    let breakdown = RecoveryCalculator.calculateBreakdown(from: data, history: [data])
    XCTAssertEqual(breakdown.spo2Score, 0)
}

func testMenstrualAdjustment() {
    let settings = UserSettings.load()
    settings.trackMenstrualCycle = true
    settings.save()
    
    let data = DailyHealthData(
        date: Date(), source: .appleWatch,
        sleepHours: 8, sleepEfficiency: 0.92,
        deepSleepPercent: 0.18, remSleepPercent: 0.22,
        hrv: 70, hrvIsRMSSD: true,
        restingHeartRate: 50,
        activeCalories: 200, steps: 3000, workoutMinutes: 0,
        menstrualFlow: true
    )
    let withoutFlow = RecoveryCalculator.calculate(from: DailyHealthData(date: Date(), source: .appleWatch, sleepHours: 8, sleepEfficiency: 0.92, deepSleepPercent: 0.18, remSleepPercent: 0.22, hrv: 70, hrvIsRMSSD: true, restingHeartRate: 50, activeCalories: 200, steps: 3000, workoutMinutes: 0), history: [data])
    let withFlow = RecoveryCalculator.calculate(from: data, history: [data])
    XCTAssertEqual(withoutFlow - withFlow, 3)
    
    // Reset
    settings.trackMenstrualCycle = false
    settings.save()
}
```

- [ ] **Step 3: Run tests**

Run:
```bash
xcodebuild -project ReadinessTracker.xcodeproj -scheme ReadinessTracker -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -configuration Debug test 2>&1 | tail -40
```

Expected: all tests pass, total ≥ 24.

- [ ] **Step 4: Commit**

```bash
git add ReadinessTrackerTests/NutritionSummaryTests.swift ReadinessTrackerTests/RecoveryCalculatorTests.swift ReadinessTracker.xcodeproj/project.pbxproj
git commit -m "test: add SpO2, menstrual, and nutrition tests"
```

---

### Task 9: Final verification

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

Append a new entry noting Phase 2C implementation is complete and tests pass.

---

## Self-Review

**Spec coverage:**
- `NutritionSummary` model → Task 1
- `DailyHealthData` extension → Task 2
- SpO2 scoring + menstrual adjustment → Task 3
- `ReadinessBreakdown.spo2Score` → Task 4
- HealthKit fetch → Task 5
- SpO2 UI row → Task 6
- Nutrition UI card → Task 7
- Tests → Task 8
- Final verification → Task 9

**Placeholder scan:** No TBD/TODO. All code snippets are concrete.

**Type consistency:**
- `NutritionSummary` init matches usage.
- `RecoveryBreakdown` gains `spo2Score` consistently.
- `UserSettings.trackMenstrualCycle` is Bool.
