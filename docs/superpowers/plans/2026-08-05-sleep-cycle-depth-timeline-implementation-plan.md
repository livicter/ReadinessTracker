# Sleep Cycle + Depth Timeline Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add real hypnogram rendering, sleep-cycle detection, and an interactive depth timeline chart to ReadinessTracker, per the design spec at `docs/superpowers/specs/2026-08-05-sleep-cycle-depth-timeline-design.md`.

**Architecture:** HealthKit raw stage samples → `SleepStageInterval` stored on `DailyHealthData.sleepStages` → `SleepCycleDetector` derives cycles → `HypnogramView` / `SleepCycleView` render them in `SleepAnalysisView` (and compactly in `DayDetailView`). `DepthTimelineChart` is a reusable interactive trend chart (baseline ±2σ bands, 7-day MA, outlier highlights, tooltip) powered by `TrendAnalysisEngine`, integrated into `TrendDetailView`, `MetricDetailView`, and `AdvancedMetricDetailView`.

**Tech Stack:** SwiftUI, Swift Charts, HealthKit (`HKCategoryValueSleepAnalysis`), XCTest. No new dependencies. iOS 16+ only (already the app floor; stage enums are already gated with `#available(iOS 16.0)`).

**Global constraints:**
- Zero new third-party dependencies.
- All existing 38 tests must keep passing.
- `DailyHealthData` custom decoder must default `sleepStages` to `[]` so old persisted data loads (backward compatibility).
- Match existing UI idioms: `NativeCard`, `RTColor.*`, `AppleTheme.*`, dark navigation bar styling, `AppSectionHeader`/`SectionHeader`.
- Build/test command throughout (from repo root `/Users/victor/Projects/ReadinessTracker`):
  ```bash
  xcodebuild -project ReadinessTracker.xcodeproj -scheme ReadinessTracker \
    -destination 'platform=iOS Simulator,name=iPhone 16' build test \
    2>&1 | tail -30
  ```
  If the scheme name fails, run `xcodebuild -list -project ReadinessTracker.xcodeproj` and substitute the correct scheme.

---

## Task 1: `SleepStageInterval` model + `DailyHealthData` extension + tests

**Files:**
- Create: `ReadinessTracker/Models/SleepStageInterval.swift`
- Modify: `ReadinessTracker/Models/HealthData.swift`
- Create: `ReadinessTrackerTests/SleepStageIntervalTests.swift`

**Interfaces:**
```swift
enum SleepStage: String, Codable, CaseIterable { case awake, light, deep, rem }
struct SleepStageInterval: Codable, Hashable { stage, startDate, endDate, durationMinutes }
// DailyHealthData gains: let sleepStages: [SleepStageInterval]
```

### Step 1.1 — Write failing tests first (TDD)

- [ ] Create `ReadinessTrackerTests/SleepStageIntervalTests.swift`:

```swift
import XCTest
@testable import ReadinessTracker

final class SleepStageIntervalTests: XCTestCase {

    func testDurationMinutes() {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let end = start.addingTimeInterval(30 * 60)
        let interval = SleepStageInterval(stage: .deep, startDate: start, endDate: end)
        XCTAssertEqual(interval.durationMinutes, 30, accuracy: 0.001)
    }

    func testCodableRoundTrip() throws {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let interval = SleepStageInterval(stage: .rem, startDate: start, endDate: start.addingTimeInterval(1200))
        let data = try JSONEncoder().encode(interval)
        let decoded = try JSONDecoder().decode(SleepStageInterval.self, from: data)
        XCTAssertEqual(decoded, interval)
    }

    func testAllStageLabelsAndColorsExist() {
        // Compile-level guarantee that every case has label + color
        for stage in SleepStage.allCases {
            XCTAssertFalse(stage.label.isEmpty)
            _ = stage.color
        }
    }

    func testDailyHealthDataDefaultsSleepStagesToEmpty() {
        let day = DailyHealthData(date: Date(), source: .appleWatch)
        XCTAssertTrue(day.sleepStages.isEmpty)
    }

    func testDailyHealthDataLegacyDecodingWithoutSleepStages() throws {
        // Minimal legacy payload: no sleepStages key must still decode
        let json = """
        {
          "id": "00000000-0000-0000-0000-000000000001",
          "date": 700000000,
          "source": "Apple Watch",
          "sleepHours": 7.5
        }
        """.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        let day = try decoder.decode(DailyHealthData.self, from: json)
        XCTAssertTrue(day.sleepStages.isEmpty)
        XCTAssertEqual(day.sleepHours, 7.5, accuracy: 0.001)
    }
}
```

Note: check how `Date` is encoded in `DataStore` (default `JSONEncoder` encodes Date as `timeIntervalSinceReferenceDate` = seconds since 2001, i.e. `700000000` above). If the legacy test fails on the date key, read `DataStore.swift` and match its date strategy.

- [ ] Run tests, confirm they fail (types don't exist):
  ```bash
  xcodebuild -project ReadinessTracker.xcodeproj -scheme ReadinessTracker \
    -destination 'platform=iOS Simulator,name=iPhone 16' \
    test -only-testing:ReadinessTrackerTests/SleepStageIntervalTests 2>&1 | tail -10
  ```
  Expected: build failure — `SleepStageInterval` unresolved.

### Step 1.2 — Create the model

- [ ] Create `ReadinessTracker/Models/SleepStageInterval.swift`:

```swift
import Foundation
import SwiftUI

enum SleepStage: String, Codable, CaseIterable {
    case awake, light, deep, rem

    var label: String {
        switch self {
        case .awake: return "Awake"
        case .light: return "Light"
        case .deep: return "Deep"
        case .rem: return "REM"
        }
    }

    /// Matches existing stage colors used across SleepAnalysisView / DayDetailView.
    var color: Color {
        switch self {
        case .awake: return RTColor.warning
        case .light: return Color.blue.opacity(0.5)
        case .deep: return RTColor.sleep
        case .rem: return Color.cyan
        }
    }

    /// Hypnogram vertical rank: Awake on top (0), Deep at the bottom (3).
    var depthRank: Int {
        switch self {
        case .awake: return 0
        case .rem: return 1
        case .light: return 2
        case .deep: return 3
        }
    }
}

struct SleepStageInterval: Codable, Hashable, Identifiable {
    let stage: SleepStage
    let startDate: Date
    let endDate: Date

    var id: Date { startDate }

    var durationMinutes: Double {
        endDate.timeIntervalSince(startDate) / 60
    }
}
```

### Step 1.3 — Extend `DailyHealthData`

- [ ] In `ReadinessTracker/Models/HealthData.swift`, add the stored property after `wakeEpisodes` (line 24):

```swift
    let wakeEpisodes: Int
    let sleepStages: [SleepStageInterval]
```

- [ ] Add to the memberwise init signature (after `wakeEpisodes: Int = 2,`):

```swift
         sleepStages: [SleepStageInterval] = [],
```

and assignment in the init body after `self.wakeEpisodes = wakeEpisodes`:

```swift
        self.sleepStages = sleepStages
```

- [ ] In the legacy init (line 109), add after `self.wakeEpisodes = 2`:

```swift
        self.sleepStages = []
```

- [ ] Add to `CodingKeys` (line 143):

```swift
        case sleepOnsetMinutes, sleepStartTime, sleepEndTime, wakeEpisodes, sleepStages
```

- [ ] Add to the custom decoder after the `wakeEpisodes` line (line 170):

```swift
        self.sleepStages = try container.decodeIfPresent([SleepStageInterval].self, forKey: .sleepStages) ?? []
```

`DailyHealthData` relies on synthesized `encode(to:)` (only a custom decoder is defined), so encoding picks up `sleepStages` automatically via `CodingKeys`.

### Step 1.4 — Verify

- [ ] Re-run the Task 1 test command. Expected: `Test Suite 'SleepStageIntervalTests' passed` — 5 tests.
- [ ] Run the full suite; all 38 existing tests + 5 new pass.

---

## Task 2: HealthKitManager raw interval storage

**Files:**
- Modify: `ReadinessTracker/Services/HealthKitManager.swift`

**Interfaces:** `fetchSleepDataForDate` return tuple gains `intervals: [SleepStageInterval]`; pure static mapper `SleepStageInterval.stage(forHealthKitValue:)` for testability.

### Step 2.1 — Write failing mapping test (TDD)

- [ ] Add to `ReadinessTrackerTests/SleepStageIntervalTests.swift`:

```swift
    func testHealthKitStageMapping() {
        // Raw values from HKCategoryValueSleepAnalysis (HealthKit/HealthKit headers)
        XCTAssertEqual(SleepStageInterval.stage(forHealthKitValue: 0), .awake)   // awake
        XCTAssertEqual(SleepStageInterval.stage(forHealthKitValue: 1), .light)   // asleepUnspecified
        XCTAssertEqual(SleepStageInterval.stage(forHealthKitValue: 2), .awake)   // inBed (not sleep — but see impl note)
        XCTAssertEqual(SleepStageInterval.stage(forHealthKitValue: 3), .light)   // asleepCore
        XCTAssertEqual(SleepStageInterval.stage(forHealthKitValue: 4), .deep)    // asleepDeep
        XCTAssertEqual(SleepStageInterval.stage(forHealthKitValue: 5), .rem)     // asleepREM
        XCTAssertNil(SleepStageInterval.stage(forHealthKitValue: 99))
    }
```

Impl note: `inBed` (2) is excluded from stage intervals — return `nil` for it and fix the test expectation accordingly (`XCTAssertNil(...forHealthKitValue: 2)`). Decide in implementation; keep the mapper returning `SleepStage?`.

- [ ] Run test — expected build failure, `stage(forHealthKitValue:)` unresolved.

### Step 2.2 — Add the mapper

- [ ] In `SleepStageInterval.swift`, add:

```swift
extension SleepStageInterval {
    /// Maps raw HKCategoryValueSleepAnalysis values. Returns nil for `.inBed`
    /// and unknown values (no stage interval should be recorded for them).
    static func stage(forHealthKitValue rawValue: Int) -> SleepStage? {
        switch rawValue {
        case 0: return .awake          // .awake
        case 1: return .light          // .asleepUnspecified
        case 3: return .light          // .asleepCore
        case 4: return .deep           // .asleepDeep
        case 5: return .rem            // .asleepREM
        default: return nil            // .inBed (2), unknown
        }
    }
}
```

- [ ] Re-run mapping test — passes.

### Step 2.3 — Extend `fetchSleepDataForDate`

- [ ] In `HealthKitManager.swift`, change both sleep tuple signatures (`fetchSleepData` line 310 and `fetchSleepDataForDate` line 322) to append `, intervals: [SleepStageInterval]` to the tuple type, and update every literal empty return `(0, 0, 0, 0, 0, 0, 15, nil, nil, 0)` to `(0, 0, 0, 0, 0, 0, 15, nil, nil, 0, [])` (4 occurrences: both guards and both `continuation.resume` failure paths).

- [ ] Inside the query result closure, before the sample loop (after line 351 `var firstAsleep: Date? = nil`), add:

```swift
                var intervals: [SleepStageInterval] = []
```

- [ ] Inside the iOS 16 branch's `switch value`, append an interval per stage case. Replace the switch body so each stage case also records the interval — the minimal-change approach is to add after the `if let value = ... {` line (before the switch):

```swift
                        if let stage = SleepStageInterval.stage(forHealthKitValue: sample.value) {
                            intervals.append(SleepStageInterval(stage: stage, startDate: sample.startDate, endDate: sample.endDate))
                        }
```

This handles all five stage cases in one place and skips `.inBed` — no per-case edits needed.

- [ ] In the pre-iOS 16 fallback branch (`else` at line 400), record intervals too:

```swift
                        if sample.value == HKCategoryValueSleepAnalysis.asleep.rawValue {
                            intervals.append(SleepStageInterval(stage: .light, startDate: sample.startDate, endDate: sample.endDate))
                            totalSleepSeconds += duration
                            ...
                        } else {
                            intervals.append(SleepStageInterval(stage: .awake, startDate: sample.startDate, endDate: sample.endDate))
                            awakeSeconds += duration
                            ...
                        }
```

(Only add the `intervals.append` lines; leave existing accumulation untouched.)

- [ ] Update the final `continuation.resume` (line 424) to sort and return intervals:

```swift
                intervals.sort { $0.startDate < $1.startDate }
                continuation.resume(returning: (
                    hours, efficiency, deepPercent, remPercent,
                    lightPercent, awakePercent, onsetMinutes,
                    firstInBed, sleepEnd, max(0, wakeEpisodes - 1), intervals
                ))
```

### Step 2.4 — Wire into `DailyHealthData` construction

- [ ] In `fetchTodayData` (line 94), add to the `DailyHealthData(...)` call after `wakeEpisodes: await sleep.wakeEpisodes,`:

```swift
            sleepStages: await sleep.intervals,
```

- [ ] In `fetchHistoricalData` (line 191), add after `wakeEpisodes: sleepValue.wakeEpisodes,`:

```swift
                sleepStages: sleepValue.intervals,
```

### Step 2.5 — Verify

- [ ] Full build + test run. Expected: `** TEST SUCCEEDED **`, all 43 tests pass. (No runtime HealthKit verification possible in CI; mapping is covered by Task 2.1.)

---

## Task 3: `SleepCycleDetector` + tests

**Files:**
- Create: `ReadinessTracker/Models/SleepCycleDetector.swift`
- Create: `ReadinessTrackerTests/SleepCycleDetectorTests.swift`

**Interfaces:**
```swift
struct SleepCycle: Hashable {
    let startDate: Date
    let endDate: Date
    let deepMinutes: Double
    let remMinutes: Double
    let lightMinutes: Double
    var durationMinutes: Double
}
enum SleepCycleDetector {
    static let awakeGapThresholdMinutes: Double = 15
    static func detectCycles(in intervals: [SleepStageInterval]) -> [SleepCycle]
    static func awakePeriods(from intervals: [SleepStageInterval]) -> [(start: Date, end: Date)]
}
```

Per the spec: a cycle is a maximal sequence of consecutive sleep stages (`.light`/`.deep`/`.rem`); an `.awake` interval longer than 15 minutes terminates the current cycle. `awakePeriods(from:)` extracts awake intervals for `SleepDisturbanceTracker`.

### Step 3.1 — Write failing tests (TDD)

- [ ] Create `ReadinessTrackerTests/SleepCycleDetectorTests.swift`:

```swift
import XCTest
@testable import ReadinessTracker

final class SleepCycleDetectorTests: XCTestCase {

    private let base = Date(timeIntervalSince1970: 1_700_000_000)

    private func iv(_ stage: SleepStage, startMin: Double, endMin: Double) -> SleepStageInterval {
        SleepStageInterval(
            stage: stage,
            startDate: base.addingTimeInterval(startMin * 60),
            endDate: base.addingTimeInterval(endMin * 60)
        )
    }

    func testEmptyInputReturnsNoCycles() {
        XCTAssertTrue(SleepCycleDetector.detectCycles(in: []).isEmpty)
    }

    func testSingleContinuousBlockIsOneCycle() {
        let intervals = [iv(.light, 0, 30), iv(.deep, 30, 60), iv(.rem, 60, 90)]
        let cycles = SleepCycleDetector.detectCycles(in: intervals)
        XCTAssertEqual(cycles.count, 1)
        XCTAssertEqual(cycles[0].durationMinutes, 90, accuracy: 0.001)
        XCTAssertEqual(cycles[0].deepMinutes, 30, accuracy: 0.001)
        XCTAssertEqual(cycles[0].remMinutes, 30, accuracy: 0.001)
        XCTAssertEqual(cycles[0].lightMinutes, 30, accuracy: 0.001)
    }

    func testShortAwakeGapDoesNotSplitCycle() {
        let intervals = [iv(.light, 0, 40), iv(.awake, 40, 50), iv(.rem, 50, 90)]
        let cycles = SleepCycleDetector.detectCycles(in: intervals)
        XCTAssertEqual(cycles.count, 1)
    }

    func testLongAwakeGapSplitsCycles() {
        let intervals = [
            iv(.light, 0, 45), iv(.deep, 45, 90),
            iv(.awake, 90, 110),                    // 20 min > 15 min threshold
            iv(.light, 110, 150), iv(.rem, 150, 180)
        ]
        let cycles = SleepCycleDetector.detectCycles(in: intervals)
        XCTAssertEqual(cycles.count, 2)
        XCTAssertEqual(cycles[0].startDate, base)
        XCTAssertEqual(cycles[0].endDate, base.addingTimeInterval(90 * 60))
        XCTAssertEqual(cycles[1].startDate, base.addingTimeInterval(110 * 60))
    }

    func testAwakeAtExactlyThresholdDoesNotSplit() {
        let intervals = [iv(.light, 0, 30), iv(.awake, 30, 45), iv(.deep, 45, 75)]
        XCTAssertEqual(SleepCycleDetector.detectCycles(in: intervals).count, 1)
    }

    func testUnsortedInputIsHandled() {
        let intervals = [iv(.rem, 60, 90), iv(.light, 0, 30), iv(.deep, 30, 60)]
        let cycles = SleepCycleDetector.detectCycles(in: intervals)
        XCTAssertEqual(cycles.count, 1)
        XCTAssertEqual(cycles[0].startDate, base)
    }

    func testAwakePeriodsExtraction() {
        let intervals = [iv(.light, 0, 30), iv(.awake, 30, 45), iv(.deep, 45, 75), iv(.awake, 75, 80)]
        let awake = SleepCycleDetector.awakePeriods(from: intervals)
        XCTAssertEqual(awake.count, 2)
        XCTAssertEqual(awake[0].start, base.addingTimeInterval(30 * 60))
        XCTAssertEqual(awake[1].end, base.addingTimeInterval(80 * 60))
    }

    func testOnlyAwakeInputReturnsNoCycles() {
        let intervals = [iv(.awake, 0, 60)]
        XCTAssertTrue(SleepCycleDetector.detectCycles(in: intervals).isEmpty)
    }
}
```

- [ ] Run `test -only-testing:ReadinessTrackerTests/SleepCycleDetectorTests` — expected build failure.

### Step 3.2 — Implement the detector

- [ ] Create `ReadinessTracker/Models/SleepCycleDetector.swift`:

```swift
import Foundation

struct SleepCycle: Hashable, Identifiable {
    let startDate: Date
    let endDate: Date
    let deepMinutes: Double
    let remMinutes: Double
    let lightMinutes: Double

    var id: Date { startDate }
    var durationMinutes: Double { endDate.timeIntervalSince(startDate) / 60 }
}

/// Detects sleep cycles from raw stage intervals.
/// A cycle ends when an awake gap exceeds `awakeGapThresholdMinutes` (spec: 15 min).
enum SleepCycleDetector {

    static let awakeGapThresholdMinutes: Double = 15

    static func detectCycles(in intervals: [SleepStageInterval]) -> [SleepCycle] {
        let sorted = intervals.sorted { $0.startDate < $1.startDate }
        var cycles: [SleepCycle] = []
        var current: [SleepStageInterval] = []

        func flush() {
            guard !current.isEmpty else { return }
            cycles.append(SleepCycle(
                startDate: current.first!.startDate,
                endDate: current.last!.endDate,
                deepMinutes: current.filter { $0.stage == .deep }.reduce(0) { $0 + $1.durationMinutes },
                remMinutes: current.filter { $0.stage == .rem }.reduce(0) { $0 + $1.durationMinutes },
                lightMinutes: current.filter { $0.stage == .light }.reduce(0) { $0 + $1.durationMinutes }
            ))
            current = []
        }

        for interval in sorted {
            if interval.stage == .awake {
                if interval.durationMinutes > awakeGapThresholdMinutes {
                    flush()
                }
                continue
            }
            current.append(interval)
        }
        flush()
        return cycles
    }

    /// Awake intervals between sleep onset and final wake, for SleepDisturbanceTracker.
    static func awakePeriods(from intervals: [SleepStageInterval]) -> [(start: Date, end: Date)] {
        intervals
            .filter { $0.stage == .awake }
            .sorted { $0.startDate < $1.startDate }
            .map { (start: $0.startDate, end: $0.endDate) }
    }
}
```

### Step 3.3 — Verify

- [ ] Run `test -only-testing:ReadinessTrackerTests/SleepCycleDetectorTests`. Expected: 8 tests pass.
- [ ] Full suite: 51 tests pass.

---

## Task 4: `HypnogramView`

**Files:**
- Create: `ReadinessTracker/Views/HypnogramView.swift`

**Interface:**
```swift
struct HypnogramView: View {
    let intervals: [SleepStageInterval]
    var interactive: Bool = true   // false = compact render for DayDetailView
}
```

### Step 4.1 — Implement the view

- [ ] Create the file with:

```swift
import SwiftUI
import Charts

/// Real hypnogram: x = time, y = stage depth (Awake top, Deep bottom).
/// Renders RectangleMark per interval; tap-to-inspect tooltip and pinch zoom
/// when `interactive` is true.
struct HypnogramView: View {
    let intervals: [SleepStageInterval]
    var interactive: Bool = true

    @State private var selected: SleepStageInterval?
    @State private var zoomScale: CGFloat = 1.0

    private var sorted: [SleepStageInterval] {
        intervals.sorted { $0.startDate < $1.startDate }
    }

    private var fullRange: ClosedRange<Date>? {
        guard let first = sorted.first, let last = sorted.last else { return nil }
        return first.startDate...last.endDate
    }

    /// Centered zoom: shrink the visible window around the midpoint.
    private var visibleDomain: ClosedRange<Date>? {
        guard let full = fullRange else { return nil }
        let total = full.upperBound.timeIntervalSince(full.lowerBound)
        let visible = total / Double(max(zoomScale, 1))
        let mid = full.lowerBound.addingTimeInterval(total / 2)
        return mid.addingTimeInterval(-visible / 2)...mid.addingTimeInterval(visible / 2)
    }

    var body: some View {
        if sorted.isEmpty {
            ContentUnavailableView(
                "No detailed stage data",
                systemImage: "bed.double",
                description: Text("Stage intervals are recorded from your next sync.")
            )
            .frame(height: 160)
        } else {
            VStack(alignment: .leading, spacing: 8) {
                chart

                if interactive, let selected {
                    tooltip(for: selected)
                }

                if interactive {
                    timeLabels
                }
            }
        }
    }

    private var chart: some View {
        Chart(sorted) { interval in
            RectangleMark(
                xStart: .value("Start", interval.startDate),
                xEnd: .value("End", interval.endDate),
                yStart: .value("Top", interval.stage.depthRank - 1),
                yEnd: .value("Bottom", interval.stage.depthRank)
            )
            .foregroundStyle(interval.stage.color)
            .opacity(selected == nil || selected == interval ? 1.0 : 0.4)
        }
        .chartYScale(domain: -4...0)
        .chartYAxis {
            AxisMarks(position: .leading, values: [-1, -2, -3, -4]) { value in
                AxisValueLabel {
                    if let rank = value.as(Int.self) {
                        Text(rankLabel(for: rank))
                            .font(.caption2)
                            .foregroundStyle(RTColor.secondaryText)
                    }
                }
            }
        }
        .chartXScale(domain: visibleDomain ?? Date()...Date())
        .chartXAxis {
            AxisMarks { _ in
                AxisGridLine().foregroundStyle(.white.opacity(0.05))
                AxisValueLabel(format: .dateTime.hour().minute())
                    .foregroundStyle(RTColor.secondaryText)
            }
        }
        .frame(height: interactive ? 180 : 100)
        .chartOverlay { proxy in
            GeometryReader { geo in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .gesture(interactive ? tapGesture(proxy: proxy, geo: geo) : nil)
                    .gesture(interactive ? zoomGesture : nil)
            }
        }
    }

    private func tapGesture(proxy: ChartProxy, geo: GeometryProxy) -> some Gesture {
        SpatialTapGesture()
            .onEnded { event in
                guard let plotFrame = proxy.plotFrame else { return }
                let x = event.location.x - geo[plotFrame].origin.x
                guard let date: Date = proxy.value(atX: x) else { return }
                selected = sorted.first { date >= $0.startDate && date < $0.endDate }
                Haptic.selectionChanged()
            }
    }

    private var zoomGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                zoomScale = min(max(value.magnification, 1), 8)
            }
    }

    private func tooltip(for interval: SleepStageInterval) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(interval.stage.color)
                .frame(width: 10, height: 10)
            Text(interval.stage.label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
            Text("\(interval.startDate, format: .dateTime.hour().minute()) – \(interval.endDate, format: .dateTime.hour().minute())")
                .font(.caption)
                .foregroundStyle(RTColor.secondaryText)
            Spacer()
            Text("\(Int(interval.durationMinutes)) min")
                .font(.caption.weight(.semibold))
                .foregroundStyle(interval.stage.color)
        }
        .padding(10)
        .background(RTColor.surfaceHighlight)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var timeLabels: some View {
        HStack {
            if let range = visibleDomain {
                Text(range.lowerBound, format: .dateTime.hour().minute())
                    .font(.caption2)
                    .foregroundStyle(RTColor.tertiaryText)
                Spacer()
                Text(range.upperBound, format: .dateTime.hour().minute())
                    .font(.caption2)
                    .foregroundStyle(RTColor.tertiaryText)
            }
        }
    }

    private func rankLabel(for rank: Int) -> String {
        // depthRank - 1 = y value; map back to stage name
        switch rank {
        case -1: return "Awake"
        case -2: return "REM"
        case -3: return "Light"
        default: return "Deep"
        }
    }
}
```

Note: if `ContentUnavailableView` isn't desired for the compact mode (iOS 17+ API), replace with a plain `Text("No detailed stage data").font(.caption).foregroundStyle(RTColor.secondaryText)` — check the deployment target; `ContentUnavailableView` requires iOS 17. Safer: use the `Text` fallback unconditionally. Adjust during implementation.

### Step 4.2 — Verify

- [ ] Full build. Expected: zero errors. (Chart rendering is verified visually in Task 7; no unit test for views, matching project convention — no existing view tests.)

---

## Task 5: `SleepCycleView`

**Files:**
- Create: `ReadinessTracker/Views/SleepCycleView.swift`

**Interface:**
```swift
struct SleepCycleView: View {
    let cycles: [SleepCycle]
}
```

### Step 5.1 — Implement the view

- [ ] Create the file with:

```swift
import SwiftUI

/// Horizontal bars per detected sleep cycle with stage composition
/// and a summary of total cycles + average length.
struct SleepCycleView: View {
    let cycles: [SleepCycle]

    private var averageMinutes: Double {
        guard !cycles.isEmpty else { return 0 }
        return cycles.reduce(0) { $0 + $1.durationMinutes } / Double(cycles.count)
    }

    var body: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Sleep Cycles")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                    Spacer()
                    Text("\(cycles.count) cycles · avg \(Int(averageMinutes)) min")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(RTColor.secondaryText)
                }

                if cycles.isEmpty {
                    Text("No cycles detected. Detailed stage data needed.")
                        .font(.caption)
                        .foregroundStyle(RTColor.secondaryText)
                } else {
                    VStack(spacing: 10) {
                        ForEach(Array(cycles.enumerated()), id: \.element.id) { index, cycle in
                            cycleRow(index: index + 1, cycle: cycle)
                        }
                    }

                    legend
                }
            }
        }
    }

    private func cycleRow(index: Int, cycle: SleepCycle) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Cycle \(index)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                Text("\(cycle.startDate, format: .dateTime.hour().minute())")
                    .font(.caption2)
                    .foregroundStyle(RTColor.tertiaryText)
                Spacer()
                Text("\(Int(cycle.durationMinutes)) min")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(RTColor.secondaryText)
            }

            GeometryReader { geo in
                let total = max(cycle.lightMinutes + cycle.deepMinutes + cycle.remMinutes, 1)
                HStack(spacing: 1) {
                    segment(width: geo.size.width * CGFloat(cycle.lightMinutes / total), color: SleepStage.light.color)
                    segment(width: geo.size.width * CGFloat(cycle.deepMinutes / total), color: SleepStage.deep.color)
                    segment(width: geo.size.width * CGFloat(cycle.remMinutes / total), color: SleepStage.rem.color)
                }
            }
            .frame(height: 14)
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        }
    }

    private func segment(width: CGFloat, color: Color) -> some View {
        Rectangle().fill(color).frame(width: max(width, 0))
    }

    private var legend: some View {
        HStack(spacing: 16) {
            ForEach([SleepStage.light, .deep, .rem], id: \.self) { stage in
                HStack(spacing: 6) {
                    Circle().fill(stage.color).frame(width: 8, height: 8)
                    Text(stage.label)
                        .font(.caption2)
                        .foregroundStyle(RTColor.secondaryText)
                }
            }
        }
    }
}
```

### Step 5.2 — Verify

- [ ] Full build. Expected: zero errors.

---

## Task 6: `DepthTimelineChart`

**Files:**
- Create: `ReadinessTracker/Views/DepthTimelineChart.swift`

**Interface:**
```swift
struct DepthTimelineChart: View {
    let title: String
    let unit: String
    let color: Color
    let points: [(date: Date, value: Double)]   // sorted by date
    var period: TrendPeriod = .week
}
```
Keeps it metric-agnostic so it serves readiness/strain (not `MetricType` cases) plus HRV/RHR/sleep. Baseline, σ, MA7, and outliers come from `TrendAnalysisEngine`.

### Step 6.1 — Implement the chart

- [ ] Create the file with:

```swift
import SwiftUI
import Charts

/// Reusable interactive depth timeline: line + area, ±2σ baseline band,
/// 7-day moving average, outlier highlighting, tap tooltip.
struct DepthTimelineChart: View {
    let title: String
    let unit: String
    let color: Color
    let points: [(date: Date, value: Double)]

    @State private var selectedIndex: Int?

    private var values: [Double] { points.map { $0.value } }

    private var baseline: Double { TrendAnalysisEngine.mean(values: values) }
    private var stdDev: Double { TrendAnalysisEngine.standardDeviation(values: values) }

    private var ma7: [Double] {
        TrendAnalysisEngine.movingAverage(values: values, window: 7)
    }

    private func isOutlier(_ value: Double) -> Bool {
        abs(TrendAnalysisEngine.zScore(value: value, baseline: baseline, stdDev: stdDev)) > 2
    }

    private var domain: ClosedRange<Double> {
        guard let lo = values.min(), let hi = values.max() else { return 0...100 }
        let pad = max((hi - lo) * 0.15, stdDev * 0.5, 0.001)
        return min(lo - pad, baseline - 2 * stdDev)...max(hi + pad, baseline + 2 * stdDev)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                Spacer()
                if let i = selectedIndex, points.indices.contains(i) {
                    Text("\(points[i].date, format: .dateTime.month().day()): \(formatted(points[i].value)) \(unit)")
                        .font(.caption)
                        .foregroundStyle(RTColor.secondaryText)
                }
            }

            if points.count >= 2 {
                Chart {
                    // ±2σ baseline band
                    if stdDev > 0 {
                        RectangleMark(
                            xStart: .value("s", points.first!.date),
                            xEnd: .value("e", points.last!.date),
                            yStart: .value("lo", baseline - 2 * stdDev),
                            yEnd: .value("hi", baseline + 2 * stdDev)
                        )
                        .foregroundStyle(color.opacity(0.08))
                    }

                    RuleMark(y: .value("Baseline", baseline))
                        .foregroundStyle(.white.opacity(0.25))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))

                    ForEach(Array(points.enumerated()), id: \.offset) { i, point in
                        LineMark(
                            x: .value("Date", point.date, unit: .day),
                            y: .value("Value", point.value)
                        )
                        .foregroundStyle(color)
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 2.5))

                        if isOutlier(point.value) {
                            PointMark(
                                x: .value("Date", point.date, unit: .day),
                                y: .value("Value", point.value)
                            )
                            .foregroundStyle(RTColor.warning)
                            .symbolSize(90)
                        } else {
                            PointMark(
                                x: .value("Date", point.date, unit: .day),
                                y: .value("Value", point.value)
                            )
                            .foregroundStyle(color.opacity(0.6))
                            .symbolSize(30)
                        }

                        // MA7 overlay (aligned: ma7[i] corresponds to points[i+6])
                        if i + 6 < ma7.count + 6, i - 6 >= 0, i - 6 < ma7.count {
                            PointMark(
                                x: .value("Date", point.date, unit: .day),
                                y: .value("MA7", ma7[i - 6])
                            )
                            .foregroundStyle(.white.opacity(0.7))
                            .symbol(.circle)
                            .symbolSize(12)
                        }
                    }
                }
                .chartYScale(domain: domain)
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisGridLine().foregroundStyle(.white.opacity(0.05))
                        AxisValueLabel().foregroundStyle(RTColor.secondaryText)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                            .foregroundStyle(RTColor.secondaryText)
                    }
                }
                .frame(height: 200)
                .chartOverlay { proxy in
                    GeometryReader { geo in
                        Rectangle()
                            .fill(.clear)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        guard let plotFrame = proxy.plotFrame else { return }
                                        let x = value.location.x - geo[plotFrame].origin.x
                                        guard let date: Date = proxy.value(atX: x) else { return }
                                        selectedIndex = points.indices.min(by: {
                                            abs(points[$0].date.timeIntervalSince(date)) <
                                            abs(points[$1].date.timeIntervalSince(date))
                                        })
                                    }
                                    .onEnded { _ in selectedIndex = nil }
                            )
                    }
                }
            } else {
                Text("Need more data")
                    .font(.caption)
                    .foregroundStyle(RTColor.secondaryText)
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func formatted(_ value: Double) -> String {
        value == floor(value) ? "\(Int(value))" : String(format: "%.1f", value)
    }
}
```

Note: the MA7 indexing — `movingAverage` returns `count - 6` values where `ma7[j]` aligns to `points[j + 6]`. The inline condition `i - 6 >= 0 && i - 6 < ma7.count` is correct; simplify the redundant first clause when implementing. If a connected MA line is preferred over points, emit `LineMark` in a second `ForEach(ma7.indices)` with x = `points[j + 6].date`.

### Step 6.2 — Verify

- [ ] Full build. Expected: zero errors.

---

## Task 7: `SleepAnalysisView` overhaul

**Files:**
- Modify: `ReadinessTracker/Views/SleepAnalysisView.swift`

### Step 7.1 — Replace the fake timeline with the hypnogram

- [ ] Replace the entire `sleepTimeline` computed property (lines 129–218) with:

```swift
    private var sleepTimeline: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Sleep Timeline")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)

                HypnogramView(intervals: data.sleepStages)

                // Legend
                HStack(spacing: 16) {
                    legendItem(color: RTColor.sleep, label: "Deep", value: "\(String(format: "%.1f", deepSleepHours))h")
                    legendItem(color: Color.cyan, label: "REM", value: "\(String(format: "%.1f", remSleepHours))h")
                    legendItem(color: Color.blue.opacity(0.5), label: "Light", value: "\(String(format: "%.1f", lightSleepHours))h")
                    legendItem(color: RTColor.warning, label: "Awake", value: "\(String(format: "%.1f", awakeHours))h")
                }
            }
        }
    }
```

- [ ] Delete the now-unused `timelineSegment(width:color:label:)` helper (lines 220–233).

### Step 7.2 — Replace the fake cycle graphic with `SleepCycleView`

- [ ] Replace the entire `sleepCyclesSection` property (lines 351–410) with:

```swift
    private var sleepCyclesSection: some View {
        SleepCycleView(cycles: SleepCycleDetector.detectCycles(in: data.sleepStages))
    }
```

- [ ] Delete the now-unused `estimatedCycles` property (lines 40–42). Check for other references first: `grep estimatedCycles` — it is only used in the old `sleepCyclesSection`, so deletion is safe. Keep the explanatory "Each cycle lasts ~90 min" sentence only if desired; the spec replaces the section outright, so drop it.

### Step 7.3 — Feed real awake intervals into `SleepDisturbanceTracker`

- [ ] In `body`, add a disturbances section after `stageBreakdown` (insert between `stageBreakdown` and `sleepCyclesSection` in the `VStack`):

```swift
                // Disturbances from real awake intervals
                SleepDisturbanceTracker(
                    awakePeriods: SleepCycleDetector.awakePeriods(from: data.sleepStages),
                    totalSleepHours: data.sleepHours,
                    sleepStart: data.sleepStartTime,
                    sleepEnd: data.sleepEndTime
                )
```

### Step 7.4 — Verify

- [ ] Full build + tests. Expected: zero errors, 51 tests pass.
- [ ] Manual smoke check in simulator: open a day with watch sleep data → Sleep Analysis shows hypnogram with real intervals, cycle bars, disturbance list. Old day without `sleepStages` shows "No detailed stage data" and no crash. (Cannot automate; note in PR.)

---

## Task 8: `DayDetailView` integration

**Files:**
- Modify: `ReadinessTracker/Views/DayDetailView.swift`

### Step 8.1 — Compact hypnogram in the sleep hero

- [ ] In `sleepDeepDive`, after the `StageLabel` HStack (line 204) and before the `NavigationLink`, insert:

```swift
                    if !data.sleepStages.isEmpty {
                        HypnogramView(intervals: data.sleepStages, interactive: false)
                    }
```

### Step 8.2 — Real awake periods in the disturbance tracker

- [ ] In `sleepStageAnalysis` (line 470), replace `awakePeriods: []` with:

```swift
            SleepDisturbanceTracker(
                awakePeriods: SleepCycleDetector.awakePeriods(from: data.sleepStages),
                totalSleepHours: data.sleepHours,
                sleepStart: data.sleepStartTime,
                sleepEnd: data.sleepEndTime
            )
```

### Step 8.3 — Verify

- [ ] Full build + tests. Expected: zero errors, 51 tests pass.
- [ ] Manual: Day detail shows compact non-interactive hypnogram for days with stage data; "Full Sleep Analysis" link still navigates via `SleepDestination`.

---

## Task 9: Depth timeline integration (TrendDetailView / MetricDetailView / AdvancedMetricDetailView)

**Files:**
- Modify: `ReadinessTracker/Views/TrendDetailView.swift`
- Modify: `ReadinessTracker/Views/MetricDetailView.swift`
- Modify: `ReadinessTracker/Views/AdvancedMetricDetailView.swift`

### Step 9.1 — TrendDetailView

- [ ] In `body`, after `mainChart` and before `metricCards`, add a per-selected-metric depth timeline section:

```swift
                // Depth timelines for selected metrics
                ForEach(Array(selectedMetrics.sorted { $0.rawValue < $1.rawValue }), id: \.self) { metric in
                    NativeCard {
                        DepthTimelineChart(
                            title: metric.rawValue,
                            unit: depthUnit(for: metric),
                            color: metric.color,
                            points: depthPoints(for: metric)
                        )
                    }
                }
```

- [ ] Add helpers to `TrendDetailView`:

```swift
    private func depthPoints(for metric: MetricToggle) -> [(date: Date, value: Double)] {
        filteredHistory.map { day in
            let value: Double
            switch metric {
            case .readiness: value = Double(readinessScore(for: day))
            case .sleep: value = day.sleepHours
            case .hrv: value = day.hrv
            case .rhr: value = day.restingHeartRate
            case .calories: value = day.activeCalories
            }
            return (date: day.date, value: value)
        }
    }

    private func depthUnit(for metric: MetricToggle) -> String {
        switch metric {
        case .readiness: return ""
        case .sleep: return "h"
        case .hrv: return "ms"
        case .rhr: return "bpm"
        case .calories: return "cal"
        }
    }
```

Note: `day.hrv` and `day.restingHeartRate` are already `Double` in the model (used directly at lines 249/261), so no casts needed there.

### Step 9.2 — MetricDetailView

- [ ] Replace the `trendChart` chart content (the `Chart(values, id: \.date)` block, lines 190–226) with `DepthTimelineChart`, preserving the period selector and empty state. Simplest minimal change: keep the card wrapper and header, replace chart body:

```swift
                if values.count >= 2 {
                    DepthTimelineChart(
                        title: "",
                        unit: metric.unit,
                        color: metric.color,
                        points: values
                    )
                } else { /* keep existing empty-state VStack */ }
```

Title is "" because the card already renders a "Trend" header — alternatively pass `title: "Trend"` and remove the inner header `Text("Trend")`. Pick one; do not double-render.

### Step 9.3 — AdvancedMetricDetailView

- [ ] Do **not** replace `AdvancedMetricChartView` (it already implements baseline bands, MA, outliers, native tooltip — this feature exists). Instead, reuse `DepthTimelineChart` nowhere here; verify `AdvancedMetricChartView` covers spec features (±2σ bands via `showBaselineBands`, MA via `showMovingAverage`, outliers via `showOutliers`, tooltip). If any spec feature is missing (e.g. pinch zoom), add `.chartXScale(domain:)` + `MagnifyGesture` to `AdvancedMetricChartView` rather than duplicating charts. (Ponytail rule: don't rebuild what exists.)

### Step 9.4 — Verify

- [ ] Full build + tests. Expected: zero errors, 51 tests pass.
- [ ] Manual: Trends screen shows depth timeline per toggled metric with baseline band and outlier dots; metric detail trend chart gains baseline band + MA + tap tooltip.

---

## Task 10: Polish — weekly report + AI recommendations + headers

**Files:**
- Modify: `ReadinessTracker/Services/WeeklyReportGenerator.swift`
- Modify: `ReadinessTracker/Services/AIRecommendations.swift`
- Modify: `ReadinessTrackerTests/AIRecommendationsTests.swift` (extend, do not rewrite)

### Step 10.1 — Weekly report sleep-cycle summary

- [ ] In `WeeklyReport` struct (line 3), add fields with decoding-safe defaults (it's `Codable`; add to init with default values and use `decodeIfPresent` if it has a custom decoder — check first; if synthesized decoding, add `= 0` defaults and a custom decoder only if persisted reports exist):

```swift
    let avgCyclesPerNight: Double
    let avgCycleLengthMinutes: Double
```

- [ ] In `generateReport`, after the sleep-hours block (around line 73), compute:

```swift
        let cycleCounts = history.map { SleepCycleDetector.detectCycles(in: $0.sleepStages).count }
        let nightsWithStages = history.filter { !$0.sleepStages.isEmpty }
        let allCycles = nightsWithStages.flatMap { SleepCycleDetector.detectCycles(in: $0.sleepStages) }
        let avgCycles = nightsWithStages.isEmpty ? 0 : Double(cycleCounts.reduce(0, +)) / Double(history.count)
        let avgCycleLength = allCycles.isEmpty ? 0 : allCycles.reduce(0) { $0 + $1.durationMinutes } / Double(allCycles.count)
```

- [ ] Pass both into the `WeeklyReport(...)` initializer call (line 120), and add to `formattedReport` after the Sleep Consistency line:

```swift
        if report.avgCyclesPerNight > 0 {
            text += "- **Sleep Cycles:** \(String(format: "%.1f", report.avgCyclesPerNight))/night, avg \(Int(report.avgCycleLengthMinutes)) min\n"
        }
```

- [ ] Add a recommendation in the recommendations block:

```swift
        if avgCycles > 0 && avgCycles < 4 {
            recommendations.append("Averaging under 4 sleep cycles per night. Longer, uninterrupted sleep completes more restorative cycles.")
        }
```

### Step 10.2 — AI recommendation for cycle quality

- [ ] In `AIRecommendations.swift`, after Rule 4 (poor sleep, line 99), add:

```swift
        // Rule 4b: Incomplete sleep cycles
        let cycles = SleepCycleDetector.detectCycles(in: latest.sleepStages)
        if !latest.sleepStages.isEmpty && cycles.count < 4 {
            recommendations.append(TrainingRecommendation(
                type: .sleepOptimization,
                title: "Incomplete Sleep Cycles",
                description: "Only \(cycles.count) complete sleep cycles detected last night. Fragmented sleep limits deep and REM recovery — aim for 7.5+ hours in bed.",
                confidence: 0.85,
                priority: .medium
            ))
        }
```

### Step 10.3 — Test the new rule (TDD tail)

- [ ] In `AIRecommendationsTests.swift`, add a test constructing a `DailyHealthData` with `sleepStages` yielding 3 cycles and asserting an "Incomplete Sleep Cycles" recommendation appears; and one with 5 cycles asserting it does not. Match the existing test file's construction style (read it first for the `generateRecommendations(for:)` entry-point setup — it reads from `DataStore`/history; follow the existing tests' fixture pattern exactly).

- [ ] Header consistency: verify `SleepAnalysisView`, `DayDetailView`, and the new sections use existing `AppSectionHeader`/`SectionHeader`/`NativeSectionHeader` consistently with neighbors (spec item 9). Only change headers that visibly diverge — no blanket renames.

### Step 10.4 — Verify

- [ ] Full build + tests. Expected: all tests pass (51 + new recommendation tests).

---

## Task 11: Final verification

- [ ] Full clean build + entire test suite:
  ```bash
  xcodebuild -project ReadinessTracker.xcodeproj -scheme ReadinessTracker \
    -destination 'platform=iOS Simulator,name=iPhone 16' clean build test 2>&1 | tail -30
  ```
  Expected: `** TEST SUCCEEDED **`, zero errors, all tests pass (38 original + ~15 new).
- [ ] Grep for leftover references to deleted code: `estimatedCycles`, `timelineSegment` — expect zero hits.
- [ ] Backward-compat check: decode a `DailyHealthData` JSON payload without `sleepStages` (covered by `testDailyHealthDataLegacyDecodingWithoutSleepStages`) — green.
- [ ] Manual simulator pass over: SleepAnalysisView (hypnogram, cycles, disturbances), DayDetailView (compact hypnogram + link), TrendDetailView (depth timelines), MetricDetailView (enhanced trend chart), old data day (graceful "No detailed stage data").
- [ ] Success criteria from spec: build clean, 38 existing tests pass, hypnogram renders real intervals, depth timelines for readiness/strain(proxy: calories)/HRV/RHR/sleep, Apple Health style preserved.

---

## Notes / decisions flagged for the implementing agent

- **`inBed` mapping**: mapper returns `nil` for `HKCategoryValueSleepAnalysis.inBed` — in-bed samples must not become stage intervals (would double-count awake time).
- **Scheme name**: `ReadinessTracker.xcodeproj` confirmed at repo root; verify scheme via `xcodebuild -list` if the build command fails. A stray `TestProject4.xcodeproj` also exists — ignore it.
- **Strain timeline**: there is no daily "strain" scalar on `DailyHealthData` (strain lives in `StrainSession`s); the TrendDetailView calories toggle is the strain proxy. True per-day strain timeline is out of scope unless the caller says otherwise.
- **`ContentUnavailableView`** requires iOS 17 — if the deployment target is 16, use the plain `Text` fallback noted in Task 4.
- **AdvancedMetricDetailView**: intentionally minimal — it already has the spec's depth-timeline features via `AdvancedMetricChartView` + `TrendAnalysisEngine.analyze`; only add pinch zoom there if missing.

Report back: plan content delivered inline (above) for writing to `/Users/victor/Projects/ReadinessTracker/docs/superpowers/plans/2026-08-05-sleep-cycle-depth-timeline-implementation-plan.md` — 11 tasks covering model+tests, HealthKit interval storage, cycle detector+tests, hypnogram, cycle view, depth timeline chart, view integrations, polish, and final verification, all with concrete Swift code and build/test commands; I could not write the file myself (read-only planning role, no Write/Edit/Bash tools).
