> I'm using the writing-plans skill to create the implementation plan.

# Workout-Level Strain Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add WHOOP-style per-workout cardiovascular strain by computing TRIMP for each `HKWorkout` using heart-rate samples captured during the workout interval.

**Architecture:** Add a focused `StrainSession` model. Refactor `StrainCalculator` to expose per-sample-array TRIMP math. Replace the workout-minutes fetch in `HealthKitManager` with a workout-session fetch, then wire the sessions into `DailyHealthData` and display them in `RecoveryStrainDetailView`.

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
| `ReadinessTracker/Models/StrainSession.swift` | New: per-workout strain session model |
| `ReadinessTracker/Models/HealthData.swift` | Modify: add `strainSessions` to `DailyHealthData` |
| `ReadinessTracker/Models/StrainCalculator.swift` | Modify: extract reusable TRIMP helper; add workout TRIMP helper |
| `ReadinessTracker/Services/HealthKitManager.swift` | Modify: fetch `HKWorkout` samples as `[StrainSession]` |
| `ReadinessTracker/Views/RecoveryStrainDetailView.swift` | Modify: show workout list |
| `ReadinessTrackerTests/StrainSessionTests.swift` | New: unit tests for workout TRIMP and encoding |

---

### Task 1: Add `StrainSession` model

**Files:**
- Create: `ReadinessTracker/Models/StrainSession.swift`

**Interfaces:**
- Produces: `StrainSession` struct with `id`, `workoutType`, `startDate`, `endDate`, `durationMinutes`, `trimp`, `contribution`

- [ ] **Step 1: Create `StrainSession.swift`**

```swift
import Foundation

struct StrainSession: Codable, Identifiable, Hashable {
    let id: UUID
    let workoutType: String
    let startDate: Date
    let endDate: Date
    let durationMinutes: Double
    let trimp: Double
    let contribution: Double
    
    init(
        id: UUID = UUID(),
        workoutType: String,
        startDate: Date,
        endDate: Date,
        trimp: Double = 0,
        contribution: Double = 0
    ) {
        self.id = id
        self.workoutType = workoutType
        self.startDate = startDate
        self.endDate = endDate
        self.durationMinutes = endDate.timeIntervalSince(startDate) / 60
        self.trimp = trimp
        self.contribution = contribution
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
git add ReadinessTracker/Models/StrainSession.swift
git commit -m "feat: add StrainSession model for workout-level strain"
```

---

### Task 2: Extend `DailyHealthData` with `strainSessions`

**Files:**
- Modify: `ReadinessTracker/Models/HealthData.swift`

**Interfaces:**
- Produces: `DailyHealthData.strainSessions: [StrainSession]`

- [ ] **Step 1: Add property and default init**

In `DailyHealthData`, add:
```swift
let strainSessions: [StrainSession]
```

In the modern `init`, add the parameter:
```swift
strainSessions: [StrainSession] = []
```

And assign it:
```swift
self.strainSessions = strainSessions
```

- [ ] **Step 2: Update legacy init**

In the legacy `init`, add:
```swift
self.strainSessions = []
```

- [ ] **Step 3: Update CodingKeys and custom decoder**

Add `strainSessions` to `CodingKeys` and in `init(from decoder:)` add:
```swift
self.strainSessions = try container.decodeIfPresent([StrainSession].self, forKey: .strainSessions) ?? []
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
git commit -m "feat: add strainSessions to DailyHealthData"
```

---

### Task 3: Refactor `StrainCalculator` for per-workout TRIMP

**Files:**
- Modify: `ReadinessTracker/Models/StrainCalculator.swift`

**Interfaces:**
- Produces: `StrainCalculator.trimp(from:restingHR:maxHR:) -> Double`
- Produces: `StrainCalculator.trimp(for:using:) -> Double`

- [ ] **Step 1: Extract reusable TRIMP helper**

Replace the body of `strainFromHRSamples(_:)` with a call to a new helper, and add the helper:

```swift
static func trimp(from samples: [HRSample], restingHR: Double, maxHR: Double) -> Double {
    let reserve = maxHR - restingHR
    guard reserve > 0 else { return 0 }
    
    var totalPoints: Double = 0
    let grouped = Dictionary(grouping: samples) { sample in
        Calendar.current.dateInterval(of: .minute, for: sample.timestamp)?.start
    }
    
    for (_, samples) in grouped {
        let avgBPM = samples.map(\.bpm).reduce(0, +) / Double(samples.count)
        let zone = max(0, min(1, (avgBPM - restingHR) / reserve))
        let points = 0.5 * exp(1.92 * zone)
        totalPoints += points
    }
    
    return totalPoints
}
```

Update `strainFromHRSamples(_:)` to:
```swift
private static func strainFromHRSamples(_ data: DailyHealthData) -> Double {
    guard data.restingHeartRate > 0,
          !data.hrSamples.isEmpty else { return 0 }
    
    let settingsMaxHR = UserSettings.load().estimatedMaxHeartRate
    guard let maxHR = data.maxHeartRate ?? (settingsMaxHR > 0 ? Double(settingsMaxHR) : nil) else { return 0 }
    
    return trimp(from: data.hrSamples, restingHR: data.restingHeartRate, maxHR: maxHR)
}
```

- [ ] **Step 2: Add workout TRIMP helper**

Add after `trimp(from:restingHR:maxHR:)`:

```swift
static func trimp(for session: StrainSession, using data: DailyHealthData) -> Double {
    guard data.restingHeartRate > 0 else { return 0 }
    let settingsMaxHR = UserSettings.load().estimatedMaxHeartRate
    guard let maxHR = data.maxHeartRate ?? (settingsMaxHR > 0 ? Double(settingsMaxHR) : nil) else { return 0 }
    
    let workoutSamples = data.hrSamples.filter { $0.timestamp >= session.startDate && $0.timestamp <= session.endDate }
    return trimp(from: workoutSamples, restingHR: data.restingHeartRate, maxHR: maxHR)
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
git add ReadinessTracker/Models/StrainCalculator.swift
git commit -m "refactor: extract reusable TRIMP helper and add workout TRIMP"
```

---

### Task 4: Fetch workouts as `StrainSession` placeholders

**Files:**
- Modify: `ReadinessTracker/Services/HealthKitManager.swift`

**Interfaces:**
- Produces: `HealthKitManager.fetchWorkouts(startOfDay:endOfDay:) -> [StrainSession]`
- Consumes: `StrainSession.init(workoutType:startDate:endDate:)`

- [ ] **Step 1: Replace `fetchWorkoutMinutes` with `fetchWorkouts`**

Replace the existing `fetchWorkoutMinutes` method with:

```swift
private func fetchWorkouts(startOfDay: Date, endOfDay: Date? = nil) async -> [StrainSession] {
    let end = endOfDay ?? Date()
    let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: end, options: .strictStartDate)
    
    return await withCheckedContinuation { continuation in
        let query = HKSampleQuery(sampleType: .workoutType(), predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]) { _, samples, _ in
            guard let workouts = samples as? [HKWorkout] else {
                continuation.resume(returning: [])
                return
            }
            
            let sessions = workouts.map { workout in
                StrainSession(
                    workoutType: self.name(for: workout.workoutActivityType),
                    startDate: workout.startDate,
                    endDate: workout.endDate
                )
            }
            continuation.resume(returning: sessions)
        }
        self.healthStore.execute(query)
    }
}

private func name(for activityType: HKWorkoutActivityType) -> String {
    switch activityType {
    case .running: return "Running"
    case .cycling: return "Cycling"
    case .walking: return "Walking"
    case .swimming: return "Swimming"
    case .yoga: return "Yoga"
    case .functionalStrengthTraining, .traditionalStrengthTraining: return "Strength"
    case .hiit: return "HIIT"
    case .hiking: return "Hiking"
    default: return "Workout"
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
git add ReadinessTracker/Services/HealthKitManager.swift
git commit -m "feat: fetch HKWorkout samples as StrainSession placeholders"
```

---

### Task 5: Wire workout sessions into daily data fetches

**Files:**
- Modify: `ReadinessTracker/Services/HealthKitManager.swift`

**Interfaces:**
- Consumes: `fetchWorkouts(startOfDay:endOfDay:) -> [StrainSession]`
- Produces: `DailyHealthData(strainSessions: ...)`

- [ ] **Step 1: Update `fetchTodayData()`**

Replace:
```swift
async let workout = fetchWorkoutMinutes(startOfDay: startOfDay)
```

With:
```swift
async let workouts = fetchWorkouts(startOfDay: startOfDay)
```

Then in the `DailyHealthData` initializer:
- Remove `workoutMinutes: await workout`
- Add `workoutMinutes: Int(await workouts.reduce(0) { $0 + $1.durationMinutes })`
- Add `strainSessions: await workouts`

- [ ] **Step 2: Update `fetchHistoricalData()`**

Replace:
```swift
async let workout = fetchWorkoutMinutes(startOfDay: startOfDay, endOfDay: endOfDay)
```

With:
```swift
async let workouts = fetchWorkouts(startOfDay: startOfDay, endOfDay: endOfDay)
```

Then replace:
```swift
let workoutValue = await workout
```

With:
```swift
let workoutsValue = await workouts
let workoutMinutesValue = Int(workoutsValue.reduce(0) { $0 + $1.durationMinutes })
```

And in the `DailyHealthData` initializer:
- Remove `workoutMinutes: workoutValue`
- Add `workoutMinutes: workoutMinutesValue`
- Add `strainSessions: workoutsValue`

- [ ] **Step 3: Build**

Run:
```bash
xcodebuild -project ReadinessTracker.xcodeproj -scheme ReadinessTracker -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -configuration Debug build 2>&1 | tail -20
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add ReadinessTracker/Services/HealthKitManager.swift
git commit -m "feat: wire StrainSession placeholders into daily and historical fetches"
```

---

### Task 6: Show workout list in `RecoveryStrainDetailView`

**Files:**
- Modify: `ReadinessTracker/Views/RecoveryStrainDetailView.swift`

**Interfaces:**
- Consumes: `data.strainSessions: [StrainSession]`
- Consumes: `StrainCalculator.trimp(for:using:)`

- [ ] **Step 1: Add workout section**

Add a new private computed property:

```swift
private var workoutSection: some View {
    NativeCard {
        VStack(alignment: .leading, spacing: 16) {
            Text("Workouts")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
            
            if data.strainSessions.isEmpty {
                Text("No recorded workouts")
                    .font(.subheadline)
                    .foregroundStyle(RTColor.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(spacing: 12) {
                    ForEach(data.strainSessions) { session in
                        WorkoutRow(session: session, trimp: StrainCalculator.trimp(for: session, using: data))
                    }
                }
            }
        }
    }
}
```

Add it to the `body` `VStack` after `advancedMetrics` (or another logical location).

- [ ] **Step 2: Add `WorkoutRow` view**

Add at the bottom of the file (outside the main struct):

```swift
private struct WorkoutRow: View {
    let session: StrainSession
    let trimp: Double
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "figure.run")
                .font(.system(size: 14))
                .foregroundStyle(RTColor.strain)
                .frame(width: 32, height: 32)
                .background(RTColor.strain.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(session.workoutType)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                
                Text("\(Int(session.durationMinutes)) min")
                    .font(.caption)
                    .foregroundStyle(RTColor.secondaryText)
            }
            
            Spacer()
            
            Text("\(Int(trimp)) TRIMP")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(RTColor.strain)
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
git commit -m "feat: show workout list with TRIMP in RecoveryStrainDetailView"
```

---

### Task 7: Unit tests for workout strain

**Files:**
- Create: `ReadinessTrackerTests/StrainSessionTests.swift`

**Interfaces:**
- Consumes: `StrainCalculator.trimp(from:restingHR:maxHR:)`
- Consumes: `StrainCalculator.trimp(for:using:)`
- Consumes: `StrainSession`, `DailyHealthData`

- [ ] **Step 1: Create the test file**

```swift
import XCTest
@testable import Readiness

final class StrainSessionTests: XCTestCase {
    func testWorkoutTRIMPFromHRSamples() {
        let base = Date()
        let samples = (0..<30).map { i in
            HRSample(timestamp: base.addingTimeInterval(TimeInterval(i * 60)), bpm: 160)
        }
        let data = DailyHealthData(
            date: base, source: .appleWatch,
            restingHeartRate: 60,
            maxHeartRate: 190,
            hrSamples: samples
        )
        let session = StrainSession(workoutType: "Running", startDate: base, endDate: base.addingTimeInterval(30 * 60))
        let trimp = StrainCalculator.trimp(for: session, using: data)
        XCTAssertGreaterThan(trimp, 0)
    }
    
    func testWorkoutOutsideSamplesReturnsZero() {
        let base = Date()
        let samples = (0..<10).map { i in
            HRSample(timestamp: base.addingTimeInterval(TimeInterval(i * 60)), bpm: 160)
        }
        let data = DailyHealthData(
            date: base, source: .appleWatch,
            restingHeartRate: 60,
            maxHeartRate: 190,
            hrSamples: samples
        )
        let later = base.addingTimeInterval(3600)
        let session = StrainSession(workoutType: "Running", startDate: later, endDate: later.addingTimeInterval(30 * 60))
        let trimp = StrainCalculator.trimp(for: session, using: data)
        XCTAssertEqual(trimp, 0, accuracy: 0.1)
    }
    
    func testDailyDataEncodesStrainSessions() throws {
        let session = StrainSession(workoutType: "Cycling", startDate: Date(), endDate: Date().addingTimeInterval(1800))
        let data = DailyHealthData(date: Date(), source: .appleWatch, strainSessions: [session])
        let encoded = try JSONEncoder().encode(data)
        let decoded = try JSONDecoder().decode(DailyHealthData.self, from: encoded)
        XCTAssertEqual(decoded.strainSessions.count, 1)
        XCTAssertEqual(decoded.strainSessions.first?.workoutType, "Cycling")
    }
}
```

- [ ] **Step 2: Add test file to test target**

Use the Ruby xcodeproj helper:
```bash
ruby -e "require 'xcodeproj'; p = Xcodeproj::Project.open('ReadinessTracker.xcodeproj'); t = p.targets.find { |x| x.name == 'ReadinessTrackerTests' }; g = p.main_group.find_subpath('ReadinessTrackerTests', true); t.add_file_references([g.new_file('StrainSessionTests.swift')]); p.save"
```

- [ ] **Step 3: Run tests**

Run:
```bash
xcodebuild -project ReadinessTracker.xcodeproj -scheme ReadinessTracker -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -configuration Debug test 2>&1 | tail -40
```

Expected: `StrainSessionTests` passes, total tests ≥ 15.

- [ ] **Step 4: Commit**

```bash
git add ReadinessTrackerTests/StrainSessionTests.swift ReadinessTracker.xcodeproj/project.pbxproj
git commit -m "test: add StrainSession encoding and workout TRIMP tests"
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

Append a new entry noting Phase 2B implementation is complete and tests pass.

---

## Self-Review

**Spec coverage:**
- `StrainSession` model → Task 1
- `DailyHealthData` extension → Task 2
- Reusable TRIMP helper + workout TRIMP → Task 3
- Fetch `HKWorkout` → Task 4
- Wire into daily/historical fetches → Task 5
- Show workout list → Task 6
- Unit tests → Task 7
- Final verification → Task 8

**Placeholder scan:** No TBD/TODO. All code snippets are concrete.

**Type consistency:**
- `StrainSession.init` parameter names match usage.
- `fetchWorkouts` returns `[StrainSession]` consistently.
- `StrainCalculator.trimp(for:using:)` takes `StrainSession` and `DailyHealthData`.
