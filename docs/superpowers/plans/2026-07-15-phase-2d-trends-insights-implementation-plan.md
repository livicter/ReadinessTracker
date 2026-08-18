> I'm using the writing-plans skill to create the implementation plan.

# Phase 2D — Trends + Insights + Weekly Report Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Surface a shareable weekly report, a strain/recovery balance score, strain-aware AI recommendations, and 7/30/90-day quick-trend cards on the Dashboard.

**Architecture:** Add a pure `StrainRecoveryBalance` value type and expose it through `DualReadinessScores`. Reuse the balance card in the Dashboard WHOOP section and `RecoveryStrainDetailView`. Extend `WeeklyReport` with average strain and render it in a new `WeeklyReportView` wired from Dashboard and History. Add focused, rule-based strain/workout recommendations to `AIRecommendationEngine`. Finally, add a `QuickTrendCard` row that aggregates `DataStore` slices with `TrendAnalysisEngine`.

**Tech Stack:** Swift 5, SwiftUI, Charts, XCTest

## Global Constraints
- iOS deployment target: 16.0+
- No new third-party dependencies
- Keep all data local (UserDefaults / HealthKit)
- No persisted model changes for existing types
- New files only when possible; modifications must remain backward compatible
- Existing `AIRecommendationEngine` output remains `[TrainingRecommendation]`
- Follow existing dark-themed Apple-native UI patterns (`RTColor`, `NativeCard`, `AppleTheme`)

---

## File Map

| File | Responsibility |
|------|----------------|
| `ReadinessTracker/Models/StrainRecoveryBalance.swift` | New: balance score + status value type |
| `ReadinessTrackerTests/StrainRecoveryBalanceTests.swift` | New: balance formula tests |
| `ReadinessTracker/Models/ReadinessCalculator.swift` | Modify: expose `balance` on `DualReadinessScores` |
| `ReadinessTracker/Views/StrainRecoveryBalanceCard.swift` | New: reusable balance card view |
| `ReadinessTracker/Views/DashboardView.swift` | Modify: add balance card and quick-trends row |
| `ReadinessTracker/Views/RecoveryStrainDetailView.swift` | Modify: show balance card + 7-day balance mini-chart |
| `ReadinessTracker/Services/WeeklyReportGenerator.swift` | Modify: add `avgStrain` to `WeeklyReport` |
| `ReadinessTracker/Views/WeeklyReportView.swift` | New: weekly report UI |
| `ReadinessTracker/Views/ContentView.swift` | Modify: add History top-row weekly-report button |
| `ReadinessTracker/Services/AIRecommendations.swift` | Modify: strain/workout rules |
| `ReadinessTrackerTests/AIRecommendationsTests.swift` | New: tests for new AI rules |
| `ReadinessTracker/Views/QuickTrendCard.swift` | New: quick-trend card view + helper |
| `ReadinessTrackerTests/QuickTrendTests.swift` | New: trend computation tests |

---

### Task 1: `StrainRecoveryBalance` model + tests

**Files:**
- Create: `ReadinessTracker/Models/StrainRecoveryBalance.swift`
- Create: `ReadinessTrackerTests/StrainRecoveryBalanceTests.swift`

**Interfaces:**
- Produces: `struct StrainRecoveryBalance { let score: Int; let status: String }`
- Produces: `static func compute(recovery: Int, strain: Double) -> StrainRecoveryBalance`

- [ ] **Step 1: Write the failing tests**

Create `ReadinessTrackerTests/StrainRecoveryBalanceTests.swift`:

```swift
import XCTest
@testable import Readiness

final class StrainRecoveryBalanceTests: XCTestCase {
    func testBalanced() {
        let balance = StrainRecoveryBalance.compute(recovery: 80, strain: 10.5)
        XCTAssertEqual(balance.score, 80)
        XCTAssertEqual(balance.status, "Balanced")
    }

    func testModerateLoad() {
        let balance = StrainRecoveryBalance.compute(recovery: 60, strain: 10.5)
        XCTAssertEqual(balance.score, 59)
        XCTAssertEqual(balance.status, "Moderate Load")
    }

    func testOverreachingRisk() {
        let balance = StrainRecoveryBalance.compute(recovery: 55, strain: 14.0)
        XCTAssertEqual(balance.score, 38)
        XCTAssertEqual(balance.status, "Overreaching Risk")
    }

    func testRestNeeded() {
        let balance = StrainRecoveryBalance.compute(recovery: 40, strain: 18.0)
        XCTAssertEqual(balance.score, 4)
        XCTAssertEqual(balance.status, "Rest Needed")
    }

    func testClampsToZeroAndHundred() {
        let low = StrainRecoveryBalance.compute(recovery: 0, strain: 21.0)
        XCTAssertEqual(low.score, 0)
        XCTAssertEqual(low.status, "Rest Needed")

        let high = StrainRecoveryBalance.compute(recovery: 100, strain: 0.0)
        XCTAssertEqual(high.score, 100)
        XCTAssertEqual(high.status, "Balanced")
    }
}
```

- [ ] **Step 2: Add the test file to the test target**

Run:

```bash
ruby -e "require 'xcodeproj'; p = Xcodeproj::Project.open('ReadinessTracker.xcodeproj'); t = p.targets.find { |x| x.name == 'ReadinessTrackerTests' }; g = p.main_group.find_subpath('ReadinessTrackerTests', true); t.add_file_references([g.new_file('StrainRecoveryBalanceTests.swift')]); p.save"
```

- [ ] **Step 3: Run tests to verify they fail**

Run:

```bash
xcodebuild -project ReadinessTracker.xcodeproj -scheme ReadinessTracker -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -configuration Debug test 2>&1 | tail -40
```

Expected: build fails with `Cannot find 'StrainRecoveryBalance' in scope`.

- [ ] **Step 4: Implement `StrainRecoveryBalance.swift`**

Create `ReadinessTracker/Models/StrainRecoveryBalance.swift`:

```swift
import Foundation

struct StrainRecoveryBalance {
    let score: Int        // 0-100
    let status: String    // "Balanced", "Moderate Load", "Overreaching Risk", "Rest Needed"

    static func compute(recovery: Int, strain: Double) -> StrainRecoveryBalance {
        let normalizedStrain = (strain / 21.0) * 100.0
        let raw = Double(recovery) - normalizedStrain
        let score = Int(min(100.0, max(0.0, raw + 50.0)))

        let status: String
        switch score {
        case 75...100:
            status = "Balanced"
        case 50..<75:
            status = "Moderate Load"
        case 25..<50:
            status = "Overreaching Risk"
        default:
            status = "Rest Needed"
        }

        return StrainRecoveryBalance(score: score, status: status)
    }
}
```

- [ ] **Step 5: Add the model file to the app target**

Run:

```bash
ruby -e "require 'xcodeproj'; p = Xcodeproj::Project.open('ReadinessTracker.xcodeproj'); t = p.targets.find { |x| x.name == 'ReadinessTracker' }; g = p.main_group.find_subpath('ReadinessTracker/Models', true); t.add_file_references([g.new_file('StrainRecoveryBalance.swift')]); p.save"
```

- [ ] **Step 6: Run tests to verify they pass**

Run:

```bash
xcodebuild -project ReadinessTracker.xcodeproj -scheme ReadinessTracker -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -configuration Debug test 2>&1 | tail -40
```

Expected: `** TEST SUCCEEDED **`

- [ ] **Step 7: Commit**

```bash
git add ReadinessTracker/Models/StrainRecoveryBalance.swift ReadinessTrackerTests/StrainRecoveryBalanceTests.swift ReadinessTracker.xcodeproj/project.pbxproj
git commit -m "feat: add StrainRecoveryBalance model and tests"
```

---

### Task 2: Expose balance + Dashboard / Recovery UI

**Files:**
- Modify: `ReadinessTracker/Models/ReadinessCalculator.swift`
- Create: `ReadinessTracker/Views/StrainRecoveryBalanceCard.swift`
- Modify: `ReadinessTracker/Views/DashboardView.swift`
- Modify: `ReadinessTracker/Views/RecoveryStrainDetailView.swift`

**Interfaces:**
- Consumes: `StrainRecoveryBalance.compute(recovery: Int, strain: Double)`
- Produces: `DualReadinessScores.balance: StrainRecoveryBalance`
- Produces: `StrainRecoveryBalanceCard(balance:)`

- [ ] **Step 1: Expose `balance` on `DualReadinessScores`**

In `ReadinessTracker/Models/ReadinessCalculator.swift`, add inside `DualReadinessScores`:

```swift
var balance: StrainRecoveryBalance {
    StrainRecoveryBalance.compute(
        recovery: general,
        strain: breakdown.strainScoreValue
    )
}
```

- [ ] **Step 2: Create the reusable balance card**

Create `ReadinessTracker/Views/StrainRecoveryBalanceCard.swift`:

```swift
import SwiftUI

struct StrainRecoveryBalanceCard: View {
    let balance: StrainRecoveryBalance

    private var zone: ScoreZone { ScoreZone(score: balance.score) }

    var body: some View {
        NativeCard {
            VStack(spacing: 12) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "scale.3d")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(zone.color)

                        Text("Balance")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(RTColor.secondaryText)
                    }

                    Spacer()

                    Text(balance.status)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(zone.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(zone.color.opacity(0.12))
                        .clipShape(Capsule())
                }

                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("\(balance.score)")
                        .font(AppleTheme.heroValue)
                        .foregroundStyle(.white)

                    Text("/ 100")
                        .font(.callout.weight(.medium))
                        .foregroundStyle(RTColor.secondaryText)
                }

                AnimatedProgressBar(
                    progress: Double(balance.score) / 100.0,
                    color: zone.color,
                    height: 8
                )
            }
        }
    }
}
```

- [ ] **Step 3: Add the card file to the app target**

Run:

```bash
ruby -e "require 'xcodeproj'; p = Xcodeproj::Project.open('ReadinessTracker.xcodeproj'); t = p.targets.find { |x| x.name == 'ReadinessTracker' }; g = p.main_group.find_subpath('ReadinessTracker/Views', true); t.add_file_references([g.new_file('StrainRecoveryBalanceCard.swift')]); p.save"
```

- [ ] **Step 4: Wire balance card into `DashboardView`**

In `ReadinessTracker/Views/DashboardView.swift`, inside `whoopSection`, insert after the `SleepPerformanceScore(...)` block:

```swift
StrainRecoveryBalanceCard(balance: scores.balance)
```

The surrounding `VStack` in `whoopSection` becomes:

```swift
VStack(spacing: AppleTheme.cardPadding) {
    HStack { ... }

    StrainRecoveryWheel(...)
        ...

    SleepPerformanceScore(...)

    StrainRecoveryBalanceCard(balance: scores.balance)

    HStack(spacing: 12) {
        if let respRate = data.respiratoryRate { ... }
        if let skinTemp = data.skinTemperature { ... }
    }
}
```

Note: `scores.balance` is a computed property on `DualReadinessScores` added in Step 1.

- [ ] **Step 5: Wire balance card and mini-chart into `RecoveryStrainDetailView`**

Add a helper property inside `RecoveryStrainDetailView`:

```swift
private var balance: StrainRecoveryBalance {
    StrainRecoveryBalance.compute(recovery: scores.general, strain: strainScore)
}

private var balanceHistory: [(date: Date, score: Int)] {
    history.map { day in
        let recovery = ReadinessCalculator.calculateBreakdown(from: day, history: history).totalScore
        let strain = StrainCalculator.calculate(from: day, history: history)
        return (day.date, StrainRecoveryBalance.compute(recovery: recovery, strain: strain).score)
    }
}
```

In `wheelSection`, replace the existing inline balance `HStack` with:

```swift
StrainRecoveryBalanceCard(balance: balance)
```

Add a new section after `wheelSection`. In `body`, add:

```swift
balanceChartSection
```

Add the new property:

```swift
private var balanceChartSection: some View {
    NativeCard {
        VStack(alignment: .leading, spacing: 16) {
            Text("7-Day Balance")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)

            if balanceHistory.count >= 2 {
                Chart(balanceHistory, id: \.date) { item in
                    BarMark(
                        x: .value("Date", item.date, unit: .day),
                        y: .value("Balance", item.score)
                    )
                    .foregroundStyle(
                        item.score >= 75 ? RTColor.optimal :
                        item.score >= 50 ? RTColor.good :
                        item.score >= 25 ? RTColor.caution : RTColor.warning
                    )
                    .cornerRadius(4, style: .continuous)
                }
                .frame(height: 140)
                .chartYScale(domain: 0...100)
            } else {
                Text("Need more data")
                    .font(.subheadline)
                    .foregroundStyle(RTColor.secondaryText)
                    .frame(height: 140)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}
```

- [ ] **Step 6: Build**

Run:

```bash
xcodebuild -project ReadinessTracker.xcodeproj -scheme ReadinessTracker -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -configuration Debug build 2>&1 | tail -20
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 7: Commit**

```bash
git add ReadinessTracker/Models/ReadinessCalculator.swift ReadinessTracker/Views/StrainRecoveryBalanceCard.swift ReadinessTracker/Views/DashboardView.swift ReadinessTracker/Views/RecoveryStrainDetailView.swift ReadinessTracker.xcodeproj/project.pbxproj
git commit -m "feat: expose strain/recovery balance card in Dashboard and detail"
```

---

### Task 3: `WeeklyReportView` + wiring

**Files:**
- Modify: `ReadinessTracker/Services/WeeklyReportGenerator.swift`
- Create: `ReadinessTracker/Views/WeeklyReportView.swift`
- Modify: `ReadinessTracker/Views/DashboardView.swift`
- Modify: `ReadinessTracker/Views/ContentView.swift`

**Interfaces:**
- Consumes: `WeeklyReportGenerator.generateReport(for:)`
- Produces: `WeeklyReport.avgStrain: Double`
- Produces: `WeeklyReportView(report: WeeklyReport)`

- [ ] **Step 1: Add `avgStrain` to `WeeklyReport`**

In `ReadinessTracker/Services/WeeklyReportGenerator.swift`, update the struct and generator.

Add the new property to `WeeklyReport`:

```swift
struct WeeklyReport: Codable {
    let weekStart: Date
    let weekEnd: Date
    let avgReadiness: Double
    let avgGymScore: Double
    let avgWorkScore: Double
    let avgSleepScore: Double
    let avgHRV: Double
    let avgRHR: Double
    let avgStrain: Double        // NEW
    let totalWorkouts: Int
    let avgWorkoutRPE: Double
    let sleepConsistency: Double
    let readinessTrend: TrendDirection
    let recommendations: [String]
    let highlights: [String]
}
```

In `generateReport(for:)`, after the readiness calculations, add:

```swift
let strains = history.map { StrainCalculator.calculate(from: $0, history: history) }
let avgStrain = strains.reduce(0, +) / Double(max(1, strains.count))
```

Pass `avgStrain: avgStrain` into the `WeeklyReport(...)` initializer.

Update `formattedReport(_:)` to include:

```swift
text += "- **Average Strain:** \(String(format: "%.1f", report.avgStrain)) / 21\n"
```

Add it after the average RHR line.

- [ ] **Step 2: Create `WeeklyReportView`**

Create `ReadinessTracker/Views/WeeklyReportView.swift`:

```swift
import SwiftUI

struct WeeklyReportView: View {
    let report: WeeklyReport
    @State private var isSharePresented = false

    private var dateRange: String {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        return "\(df.string(from: report.weekStart)) – \(df.string(from: report.weekEnd))"
    }

    private var trendText: String {
        switch report.readinessTrend {
        case .up: return "Improving"
        case .down: return "Declining"
        case .flat: return "Stable"
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: AppleTheme.sectionSpacing) {
                headerCard
                statGrid
                highlightsSection
                recommendationsSection
                shareButton
            }
            .padding(.horizontal, AppleTheme.horizontalMargin)
            .padding(.vertical, 12)
        }
        .background(RTColor.background.ignoresSafeArea())
        .navigationTitle("Weekly Report")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(RTColor.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $isSharePresented) {
            ShareSheet(activityItems: [WeeklyReportGenerator.shared.formattedReport(report)])
        }
    }

    private var headerCard: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(dateRange)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(RTColor.secondaryText)

                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("\(Int(report.avgReadiness))")
                        .font(AppleTheme.heroValue)
                        .foregroundStyle(.white)

                    Text("% avg readiness")
                        .font(.callout.weight(.medium))
                        .foregroundStyle(RTColor.secondaryText)
                }

                HStack(spacing: 6) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RTColor.optimal)
                    Text(trendText)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(RTColor.secondaryText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var statGrid: some View {
        let columns = [GridItem(.flexible()), GridItem(.flexible())]

        return LazyVGrid(columns: columns, spacing: 12) {
            StatGridItem(label: "Gym", value: "\(Int(report.avgGymScore))", unit: "%", trend: nil)
            StatGridItem(label: "Work", value: "\(Int(report.avgWorkScore))", unit: "%", trend: nil)
            StatGridItem(label: "Sleep", value: "\(Int(report.avgSleepScore))", unit: "%", trend: nil)
            StatGridItem(label: "HRV", value: "\(Int(report.avgHRV))", unit: "ms", trend: nil)
            StatGridItem(label: "RHR", value: "\(Int(report.avgRHR))", unit: "bpm", trend: nil)
            StatGridItem(label: "Strain", value: String(format: "%.1f", report.avgStrain), unit: "/21", trend: nil)
            StatGridItem(label: "Workouts", value: "\(report.totalWorkouts)", unit: "", trend: nil)
            StatGridItem(label: "Avg RPE", value: "\(Int(report.avgWorkoutRPE))", unit: "/10", trend: nil)
        }
    }

    @ViewBuilder
    private var highlightsSection: some View {
        if !report.highlights.isEmpty {
            NativeCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Highlights")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(report.highlights, id: \.self) { highlight in
                            Label(highlight, systemImage: "checkmark.circle.fill")
                                .font(.subheadline)
                                .foregroundStyle(RTColor.optimal)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    @ViewBuilder
    private var recommendationsSection: some View {
        if !report.recommendations.isEmpty {
            NativeCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recommendations")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(report.recommendations, id: \.self) { rec in
                            Label(rec, systemImage: "lightbulb.fill")
                                .font(.subheadline)
                                .foregroundStyle(RTColor.caution)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var shareButton: some View {
        Button {
            isSharePresented = true
        } label: {
            Label("Share Report", systemImage: "square.and.arrow.up")
                .font(.subheadline.weight(.semibold))
                .padding()
                .frame(maxWidth: .infinity)
                .background(RTColor.optimal)
                .foregroundStyle(.black)
                .clipShape(RoundedRectangle(cornerRadius: AppleTheme.cornerRadiusMedium, style: .continuous))
        }
    }
}
```

- [ ] **Step 3: Add the view file to the app target**

Run:

```bash
ruby -e "require 'xcodeproj'; p = Xcodeproj::Project.open('ReadinessTracker.xcodeproj'); t = p.targets.find { |x| x.name == 'ReadinessTracker' }; g = p.main_group.find_subpath('ReadinessTracker/Views', true); t.add_file_references([g.new_file('WeeklyReportView.swift')]); p.save"
```

- [ ] **Step 4: Wire `WeeklyReportView` from `DashboardView`**

In `ReadinessTracker/Views/DashboardView.swift`, add state:

```swift
@State private var isWeeklyReportPresented = false
```

Add a toolbar to the `NavigationStack`. After `.toolbarColorScheme(.dark, for: .navigationBar)`, add:

```swift
.toolbar {
    ToolbarItem(placement: .navigationBarTrailing) {
        Button {
            isWeeklyReportPresented = true
        } label: {
            Image(systemName: "doc.text")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
        }
    }
}
.sheet(isPresented: $isWeeklyReportPresented) {
    if let report = WeeklyReportGenerator.shared.generateReport(for: selectedSource) {
        NavigationStack {
            WeeklyReportView(report: report)
        }
    } else {
        Text("Need at least 3 days of data for a weekly report")
            .foregroundStyle(RTColor.secondaryText)
            .padding()
    }
}
```

- [ ] **Step 5: Wire `WeeklyReportView` from `HistoryView`**

In `ReadinessTracker/Views/ContentView.swift`, add state to `HistoryView`:

```swift
@State private var showWeeklyReport = false
```

Add a top-row button inside the `List`, before `Section("Trends")`:

```swift
Button {
    showWeeklyReport = true
} label: {
    HStack(spacing: 12) {
        Image(systemName: "doc.text")
            .font(.system(size: 18))
            .foregroundStyle(RTColor.optimal)
            .frame(width: 36, height: 36)
            .background(RTColor.optimal.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

        VStack(alignment: .leading, spacing: 2) {
            Text("Weekly Report")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)

            Text("Review last 7 days")
                .font(.caption)
                .foregroundStyle(RTColor.secondaryText)
        }

        Spacer()

        Image(systemName: "chevron.right")
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(RTColor.tertiaryText)
    }
    .padding(16)
    .background(RTColor.surface)
    .clipShape(RoundedRectangle(cornerRadius: AppleTheme.cornerRadiusLarge, style: .continuous))
}
.buttonStyle(.plain)
.listRowSeparator(.hidden)
.listRowBackground(Color.clear)
```

Add a sheet to `HistoryView`:

```swift
.sheet(isPresented: $showWeeklyReport) {
    if let report = WeeklyReportGenerator.shared.generateReport(for: selectedSource) {
        NavigationStack {
            WeeklyReportView(report: report)
        }
    } else {
        Text("Need at least 3 days of data for a weekly report")
            .foregroundStyle(RTColor.secondaryText)
            .padding()
    }
}
```

- [ ] **Step 6: Build**

Run:

```bash
xcodebuild -project ReadinessTracker.xcodeproj -scheme ReadinessTracker -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -configuration Debug build 2>&1 | tail -20
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 7: Commit**

```bash
git add ReadinessTracker/Services/WeeklyReportGenerator.swift ReadinessTracker/Views/WeeklyReportView.swift ReadinessTracker/Views/DashboardView.swift ReadinessTracker/Views/ContentView.swift ReadinessTracker.xcodeproj/project.pbxproj
git commit -m "feat: add WeeklyReportView and wire from Dashboard and History"
```

---

### Task 4: AI recommendations strain/workout rules + tests

**Files:**
- Modify: `ReadinessTracker/Services/AIRecommendations.swift`
- Create: `ReadinessTrackerTests/AIRecommendationsTests.swift`

**Interfaces:**
- Consumes: `StrainCalculator.calculate`, `BaselineManager.hrvBaseline`, `MetadataStore` RPE/workout flags
- Produces: new `TrainingRecommendation` entries from rules 10-13

- [ ] **Step 1: Write the failing tests**

Create `ReadinessTrackerTests/AIRecommendationsTests.swift`:

```swift
import XCTest
@testable import Readiness

@MainActor
final class AIRecommendationsTests: XCTestCase {
    private let engine = AIRecommendationEngine.shared

    override func setUp() {
        super.setUp()
        DataStore.shared.history = []
        MetadataStore.shared.entries = []
    }

    override func tearDown() {
        DataStore.shared.history = []
        MetadataStore.shared.entries = []
        super.tearDown()
    }

    func testHighStrainAndLowRecoveryTriggersCriticalRest() {
        let day = DailyHealthData(
            date: Date(), source: .appleWatch,
            activeCalories: 6000, workoutMinutes: 180,
            hrv: 20, restingHeartRate: 75
        )
        DataStore.shared.history = [day]

        let recs = engine.generateRecommendations(for: .appleWatch)
        XCTAssertNotNil(recs.first { $0.title == "Critical Rest Day" })
    }

    func testThreeConsecutiveWorkoutsWithHighRPETriggersTaper() {
        let base = Date()
        let days = (0..<4).map { i in
            DailyHealthData(
                date: base.addingTimeInterval(TimeInterval(i) * 86400),
                source: .appleWatch,
                hrv: 50, restingHeartRate: 60
            )
        }
        DataStore.shared.history = days

        for day in days {
            let meta = UserMetadata(
                date: day.date,
                timeOfDay: .evening,
                workoutToday: true,
                workoutRPE: 8
            )
            MetadataStore.shared.save(meta)
        }

        let recs = engine.generateRecommendations(for: .appleWatch)
        XCTAssertNotNil(recs.first { $0.title == "Taper Recommended" })
    }

    func testHighReadinessLowStrainTriggersProgressiveOverload() {
        let day = DailyHealthData(
            date: Date(), source: .appleWatch,
            sleepHours: 8, sleepEfficiency: 0.92,
            deepSleepPercent: 0.18, remSleepPercent: 0.22,
            hrv: 75, hrvIsRMSSD: true,
            restingHeartRate: 48,
            activeCalories: 200, steps: 3000, workoutMinutes: 0
        )
        DataStore.shared.history = [day]

        let recs = engine.generateRecommendations(for: .appleWatch)
        XCTAssertNotNil(recs.first { $0.title == "Progressive Overload Window" })
    }

    func testHardWorkoutFollowedByLowHRVTriggersRecoveryWarning() {
        let base = Date()
        let day1 = DailyHealthData(
            date: base, source: .appleWatch,
            hrv: 50, restingHeartRate: 60
        )
        let day2 = DailyHealthData(
            date: base.addingTimeInterval(86400), source: .appleWatch,
            hrv: 30, restingHeartRate: 62
        )
        DataStore.shared.history = [day1, day2]

        let meta = UserMetadata(
            date: base,
            timeOfDay: .evening,
            workoutToday: true,
            workoutRPE: 9
        )
        MetadataStore.shared.save(meta)

        let recs = engine.generateRecommendations(for: .appleWatch)
        XCTAssertNotNil(recs.first { $0.title == "Recovery Warning" })
    }
}
```

- [ ] **Step 2: Add the test file to the test target**

Run:

```bash
ruby -e "require 'xcodeproj'; p = Xcodeproj::Project.open('ReadinessTracker.xcodeproj'); t = p.targets.find { |x| x.name == 'ReadinessTrackerTests' }; g = p.main_group.find_subpath('ReadinessTrackerTests', true); t.add_file_references([g.new_file('AIRecommendationsTests.swift')]); p.save"
```

- [ ] **Step 3: Run tests to verify they fail**

Run:

```bash
xcodebuild -project ReadinessTracker.xcodeproj -scheme ReadinessTracker -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -configuration Debug test 2>&1 | tail -40
```

Expected: tests fail because the new recommendation titles are not produced.

- [ ] **Step 4: Implement the new rules**

In `ReadinessTracker/Services/AIRecommendations.swift`, add the helper before the closing `}` of the class:

```swift
private func consecutiveWorkoutRuns(in history: [DailyHealthData]) -> [[UserMetadata]] {
    var runs: [[UserMetadata]] = []
    var current: [UserMetadata] = []

    for day in history {
        if let evening = MetadataStore.shared.metadataFor(date: day.date, timeOfDay: .evening),
           evening.workoutToday == true {
            current.append(evening)
        } else {
            if current.count >= 3 { runs.append(current) }
            current = []
        }
    }
    if current.count >= 3 { runs.append(current) }

    return runs
}
```

Insert the new rules inside `generateRecommendations(for:)` just before the existing `// Sort by priority` comment:

```swift
// Rule 10: High strain + low recovery -> critical rest
let latestStrain = StrainCalculator.calculate(from: latest, history: history)
if latestStrain > 14 && dualScores.general < 50 {
    recommendations.append(TrainingRecommendation(
        type: .restDay,
        title: "Critical Rest Day",
        description: "Strain is \(String(format: "%.1f", latestStrain)) and readiness is only \(dualScores.general)%. Avoid hard training today.",
        confidence: 0.93,
        priority: .critical
    ))
}

// Rule 11: 3+ consecutive workout days with avg RPE >= 7 -> taper
for run in consecutiveWorkoutRuns(in: history) {
    let avgRPE = Double(run.compactMap { $0.workoutRPE }.reduce(0, +)) / Double(run.count)
    if avgRPE >= 7 {
        recommendations.append(TrainingRecommendation(
            type: .workoutIntensity,
            title: "Taper Recommended",
            description: "You've trained \(run.count) days in a row at an average RPE of \(Int(avgRPE)). Reduce load for 1-2 days.",
            confidence: 0.85,
            priority: .high
        ))
    }
}

// Rule 12: Recovery > 80 and strain < 7 -> progressive overload window
if dualScores.general > 80 && latestStrain < 7 {
    recommendations.append(TrainingRecommendation(
        type: .workoutIntensity,
        title: "Progressive Overload Window",
        description: "Readiness is high (\(dualScores.general)%) and strain is low. Good day to add 5-10% load.",
        confidence: 0.78,
        priority: .low
    ))
}

// Rule 13: Hard workout today and next-day HRV < baseline * 0.9 -> recovery warning
let hrvBaseline = BaselineManager.hrvBaseline(from: history, matchesRMSSD: latest.hrvIsRMSSD)
for i in 0..<(history.count - 1) {
    let day = history[i]
    let nextDay = history[i + 1]

    if let evening = MetadataStore.shared.metadataFor(date: day.date, timeOfDay: .evening),
       let rpe = evening.workoutRPE, rpe >= 8,
       nextDay.hrv > 0, Double(nextDay.hrv) < hrvBaseline * 0.9 {
        recommendations.append(TrainingRecommendation(
            type: .restDay,
            title: "Recovery Warning",
            description: "A hard workout (RPE \(rpe)) was followed by below-baseline HRV. Prioritize recovery.",
            confidence: 0.86,
            priority: .high
        ))
    }
}
```

- [ ] **Step 5: Run tests to verify they pass**

Run:

```bash
xcodebuild -project ReadinessTracker.xcodeproj -scheme ReadinessTracker -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -configuration Debug test 2>&1 | tail -40
```

Expected: `** TEST SUCCEEDED **`

- [ ] **Step 6: Commit**

```bash
git add ReadinessTracker/Services/AIRecommendations.swift ReadinessTrackerTests/AIRecommendationsTests.swift ReadinessTracker.xcodeproj/project.pbxproj
git commit -m "feat: add strain/workout-aware AI recommendation rules and tests"
```

---

### Task 5: `QuickTrendCard` row + tests

**Files:**
- Create: `ReadinessTracker/Views/QuickTrendCard.swift`
- Create: `ReadinessTrackerTests/QuickTrendTests.swift`
- Modify: `ReadinessTracker/Views/DashboardView.swift`

**Interfaces:**
- Consumes: `DataStore.dataForSource`, `TrendAnalysisEngine.linearRegression`, `TrendAnalysisEngine.classifyTrend`
- Produces: `QuickTrendCard(metric:history:window:)`

- [ ] **Step 1: Write the failing tests**

Create `ReadinessTrackerTests/QuickTrendTests.swift`:

```swift
import XCTest
@testable import Readiness

final class QuickTrendTests: XCTestCase {
    func testAverageAndPercentChange() {
        let history = (1...14).map { i in
            DailyHealthData(
                date: Date().addingTimeInterval(TimeInterval(i) * 86400),
                source: .appleWatch,
                activeCalories: Double(i * 100)
            )
        }

        let trend = QuickTrendCard.computeTrend(metric: .activeCalories, history: history, window: 7)

        XCTAssertEqual(trend.average, 1100, accuracy: 0.1)
        XCTAssertEqual(trend.percentChange, 175, accuracy: 0.1)
    }

    func testIncreasingValuesYieldStrongUp() {
        let history = (1...7).map { i in
            DailyHealthData(
                date: Date().addingTimeInterval(TimeInterval(i) * 86400),
                source: .appleWatch,
                activeCalories: Double(i * 100)
            )
        }

        let trend = QuickTrendCard.computeTrend(metric: .activeCalories, history: history, window: 7)

        XCTAssertEqual(trend.strength, .strongUp)
    }

    func testImprovingRestingHRYieldsStrongUp() {
        let history = (0..<7).map { i in
            DailyHealthData(
                date: Date().addingTimeInterval(TimeInterval(i) * 86400),
                source: .appleWatch,
                restingHeartRate: Double(80 - i * 5)
            )
        }

        let trend = QuickTrendCard.computeTrend(metric: .restingHR, history: history, window: 7)

        XCTAssertEqual(trend.strength, .strongUp)
    }
}
```

- [ ] **Step 2: Add the test file to the test target**

Run:

```bash
ruby -e "require 'xcodeproj'; p = Xcodeproj::Project.open('ReadinessTracker.xcodeproj'); t = p.targets.find { |x| x.name == 'ReadinessTrackerTests' }; g = p.main_group.find_subpath('ReadinessTrackerTests', true); t.add_file_references([g.new_file('QuickTrendTests.swift')]); p.save"
```

- [ ] **Step 3: Run tests to verify they fail**

Run:

```bash
xcodebuild -project ReadinessTracker.xcodeproj -scheme ReadinessTracker -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -configuration Debug test 2>&1 | tail -40
```

Expected: tests fail because `QuickTrendCard` does not exist.

- [ ] **Step 4: Implement `QuickTrendCard`**

Create `ReadinessTracker/Views/QuickTrendCard.swift`:

```swift
import SwiftUI

struct QuickTrend {
    let window: Int
    let average: Double
    let percentChange: Double
    let strength: TrendAnalysisEngine.TrendStrength
    let sparkline: [Double]
}

struct QuickTrendCard: View {
    let metric: MetricType
    let history: [DailyHealthData]
    let window: Int

    private var trend: QuickTrend {
        QuickTrendCard.computeTrend(metric: metric, history: history, window: window)
    }

    var body: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: metric.icon)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(metric.color)

                        Text(metric.title)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(RTColor.secondaryText)
                    }

                    Spacer()

                    Text(trend.strength.rawValue)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(trend.strength.trendColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(trend.strength.trendColor.opacity(0.12))
                        .clipShape(Capsule())
                }

                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(formattedAverage(trend.average))
                        .font(AppleTheme.cardValue)
                        .foregroundStyle(.white)

                    Text(metric.unit)
                        .font(.callout.weight(.medium))
                        .foregroundStyle(RTColor.secondaryText)
                }

                HStack(spacing: 4) {
                    Image(systemName: percentChangeDirection.systemImage)
                        .font(.caption.weight(.semibold))

                    Text(percentChangeText)
                        .font(.caption.weight(.medium))
                }
                .foregroundStyle(percentChangeColor)

                if trend.sparkline.count >= 2 {
                    AnimatedSparkline(data: trend.sparkline, color: metric.color)
                        .frame(height: 32)
                }
            }
        }
    }

    private var percentChange: Double { trend.percentChange }

    private var percentChangeDirection: TrendDirection {
        percentChange > 0 ? .up : percentChange < 0 ? .down : .flat
    }

    private var percentChangeText: String {
        let sign = percentChange >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.0f", percentChange))% vs prior window"
    }

    private var percentChangeColor: Color {
        if metric.higherIsBetter {
            return percentChange >= 0 ? RTColor.optimal : RTColor.warning
        } else {
            return percentChange >= 0 ? RTColor.warning : RTColor.optimal
        }
    }

    private func formattedAverage(_ value: Double) -> String {
        switch metric {
        case .sleep:
            return String(format: "%.1f", value)
        case .hrv, .restingHR, .activeCalories:
            return "\(Int(value))"
        case .bloodOxygen:
            return String(format: "%.0f", value)
        }
    }

    static func computeTrend(metric: MetricType, history: [DailyHealthData], window: Int) -> QuickTrend {
        let values = history.map { metricValue($0, metric: metric) }
        let current = Array(values.suffix(window))
        let previous = Array(values.dropLast(window).suffix(window))

        let currentAvg = current.reduce(0, +) / Double(max(1, current.count))
        let previousAvg = previous.reduce(0, +) / Double(max(1, previous.count))
        let percentChange = previousAvg > 0 ? (currentAvg - previousAvg) / previousAvg * 100 : 0

        let (slope, rSquared, _) = TrendAnalysisEngine.linearRegression(values: current)
        let strength = TrendAnalysisEngine.classifyTrend(slope: slope, rSquared: rSquared, metric: metric)

        return QuickTrend(
            window: window,
            average: currentAvg,
            percentChange: percentChange,
            strength: strength,
            sparkline: current
        )
    }

    static func metricValue(_ data: DailyHealthData, metric: MetricType) -> Double {
        switch metric {
        case .sleep: return data.sleepHours
        case .hrv: return data.hrv
        case .restingHR: return data.restingHeartRate
        case .activeCalories: return data.activeCalories
        case .bloodOxygen: return data.bloodOxygen ?? 0
        }
    }
}

extension TrendAnalysisEngine.TrendStrength {
    var trendColor: Color {
        switch self {
        case .strongUp, .moderateUp:
            return RTColor.optimal
        case .flat:
            return RTColor.tertiaryText
        case .moderateDown, .strongDown:
            return RTColor.warning
        }
    }
}
```

- [ ] **Step 5: Add the view file to the app target**

Run:

```bash
ruby -e "require 'xcodeproj'; p = Xcodeproj::Project.open('ReadinessTracker.xcodeproj'); t = p.targets.find { |x| x.name == 'ReadinessTracker' }; g = p.main_group.find_subpath('ReadinessTracker/Views', true); t.add_file_references([g.new_file('QuickTrendCard.swift')]); p.save"
```

- [ ] **Step 6: Add the quick-trends row to `DashboardView`**

In `ReadinessTracker/Views/DashboardView.swift`, add state:

```swift
@State private var quickTrendWindow: Int = 7
```

In the body, where `history` is computed, also compute a longer history for quick trends:

```swift
let history = dataStore.dataForSource(selectedSource, days: trendPeriod.rawValue)
let longHistory = dataStore.dataForSource(selectedSource, days: 90)
```

Add the section after `metricsSection(data: data, history: history)` and before `sleepSection(data: data)`:

```swift
quickTrendsSection(history: longHistory)
```

Add the helper:

```swift
private func quickTrendsSection(history: [DailyHealthData]) -> some View {
    VStack(spacing: AppleTheme.cardPadding) {
        HStack {
            SectionHeader(title: "Quick Trends") {}
            Spacer()

            Picker("", selection: $quickTrendWindow) {
                Text("7D").tag(7)
                Text("30D").tag(30)
                Text("90D").tag(90)
            }
            .pickerStyle(.segmented)
            .frame(width: 150)
        }

        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                QuickTrendCard(metric: .sleep, history: history, window: quickTrendWindow)
                    .frame(width: 160)

                QuickTrendCard(metric: .hrv, history: history, window: quickTrendWindow)
                    .frame(width: 160)

                QuickTrendCard(metric: .restingHR, history: history, window: quickTrendWindow)
                    .frame(width: 160)

                QuickTrendCard(metric: .activeCalories, history: history, window: quickTrendWindow)
                    .frame(width: 160)
            }
        }
    }
}
```

- [ ] **Step 7: Run tests to verify they pass**

Run:

```bash
xcodebuild -project ReadinessTracker.xcodeproj -scheme ReadinessTracker -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -configuration Debug test 2>&1 | tail -40
```

Expected: `** TEST SUCCEEDED **`

- [ ] **Step 8: Commit**

```bash
git add ReadinessTracker/Views/QuickTrendCard.swift ReadinessTracker/Views/DashboardView.swift ReadinessTrackerTests/QuickTrendTests.swift ReadinessTracker.xcodeproj/project.pbxproj
git commit -m "feat: add QuickTrendCard row with 7/30/90-day windows and tests"
```

---

### Task 6: Final verification

**Files:**
- All touched files

- [ ] **Step 1: Run full test suite**

Run:

```bash
xcodebuild -project ReadinessTracker.xcodeproj -scheme ReadinessTracker -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -configuration Debug test 2>&1 | tail -40
```

Expected: `** TEST SUCCEEDED **`

- [ ] **Step 2: Check git status**

Run:

```bash
git status --short
```

Expected: working tree clean (all changes committed).

- [ ] **Step 3: Update `progress.md`**

Append a new entry noting Phase 2D implementation is complete and all tests pass.

---

## Self-Review

**Spec coverage:**
- `StrainRecoveryBalance` model + tests → Task 1
- Balance card on Dashboard / `RecoveryStrainDetailView` → Task 2
- `WeeklyReportView` + History wiring → Task 3
- AI strain/workout rules + tests → Task 4
- `QuickTrendCard` row + tests → Task 5
- Final verification → Task 6

**Placeholder scan:** No TBD/TODO. All code snippets are concrete.

**Type consistency:**
- `StrainRecoveryBalance.compute(recovery: Int, strain: Double)` used everywhere.
- `DualReadinessScores.balance` derives from `general` and `breakdown.strainScoreValue`.
- `WeeklyReport.avgStrain` is `Double` and rendered with `%.1f`.
- `QuickTrendCard.computeTrend(metric:history:window:)` returns `QuickTrend` matching the view's expectations.
