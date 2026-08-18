> I'm using the writing-plans skill to create the implementation plan.

# Glassy UI Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Convert every view to Apple-style glassmorphism (translucent materials, blur, rounded corners, subtle borders, soft shadows) while preserving all functionality.

**Architecture:** Add glass tokens to `RTColor`/`AppleTheme`. Redefine `NativeCard` to use `.ultraThinMaterial` with a subtle gradient overlay, border, and shadow. Add `GlassRow` and `GlassBackground`. Update shared components and every view to use the new glass surfaces. Existing `GlassCard` callers automatically upgrade because `GlassCard` delegates to `NativeCard`.

**Tech Stack:** Swift 5, SwiftUI, Charts, XCTest

## Global Constraints
- iOS deployment target: 16.0+
- No new third-party dependencies
- Keep all data local (UserDefaults / HealthKit)
- No persisted model changes
- Existing unit tests must pass
- Follow existing dark-themed Apple-native UI patterns

---

## File Map

| File | Responsibility |
|------|----------------|
| `ReadinessTracker/Design/Theme.swift` | Add glass color tokens |
| `ReadinessTracker/Design/AppleNativeTheme.swift` | Update `NativeCard`, `StatGridItem`, `NativePeriodSelector`, `OutlierCallout` |
| `ReadinessTracker/Design/Components.swift` | Add `GlassRow`, `GlassBackground`; keep `GlassCard` delegating to `NativeCard` |
| `ReadinessTracker/Views/ContentView.swift` | Glass tab bar, HistoryView rows, trend chart |
| `ReadinessTracker/Views/DashboardView.swift` | Glass hero, metric grid, quick trends, WHOOP section, recommendation card |
| `ReadinessTracker/Views/ReadinessDetailView.swift` | Glass breakdown, component rows, history chart |
| `ReadinessTracker/Views/RecoveryStrainDetailView.swift` | Glass wheel, balance, nutrition, workouts, history chart |
| `ReadinessTracker/Views/DayDetailView.swift` | Glass ring, metrics, context cards |
| `ReadinessTracker/Views/SleepAnalysisView.swift` | Glass timeline, stage cards, debt |
| `ReadinessTracker/Views/TrendDetailView.swift` | Glass chart card, stat cards, selectors |
| `ReadinessTracker/Views/MetricDetailView.swift` | Glass cards |
| `ReadinessTracker/Views/AdvancedMetricDetailView.swift` | Glass hero, toggles, distribution |
| `ReadinessTracker/Views/AdvancedMetricChartView.swift` | Glass chart card |
| `ReadinessTracker/Views/SmartInsightsView.swift` | Glass insight cards |
| `ReadinessTracker/Views/RecoveryTrajectoryView.swift` | Glass bars |
| `ReadinessTracker/Views/WeeklyPatternView.swift` | Glass day-of-week bars |
| `ReadinessTracker/Views/DistributionHistogramView.swift` | Glass histogram card |
| `ReadinessTracker/Views/MetricCorrelationView.swift` | Glass scatter card |
| `ReadinessTracker/Views/WeeklyReportView.swift` | Glass header, stat grid, highlights |
| `ReadinessTracker/Views/QuickTrendCard.swift` | Glass card |
| `ReadinessTracker/Views/StrainRecoveryBalanceCard.swift` | Glass card |
| `ReadinessTracker/Views/JournalView.swift` | Glass form and entry cards |
| `ReadinessTracker/Views/CheckInView.swift` | Glass form, buttons |
| `ReadinessTracker/Views/BreathingView.swift` | Glass instructions, timer card |
| `ReadinessTracker/Views/SyncStatusView.swift` | Glass pill |
| `ReadinessTracker/Views/WhoopFeatures/*.swift` | Glass styling |

---

## Glass Patterns (use these in every task)

### 1. `NativeCard` (new glass implementation)

Replace the existing `NativeCard` body in `AppleNativeTheme.swift` with:

```swift
struct NativeCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(AppleTheme.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: AppleTheme.cornerRadiusLarge, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        LinearGradient(
                            colors: [RTColor.glassHighlight, .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppleTheme.cornerRadiusLarge, style: .continuous)
                            .stroke(RTColor.glassBorder, lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(AppleTheme.glassShadowOpacity), radius: AppleTheme.glassShadowRadius, x: 0, y: AppleTheme.glassShadowY)
            )
    }
}
```

### 2. `GlassRow`

Add to `Components.swift`:

```swift
struct GlassRow<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: AppleTheme.cornerRadiusMedium, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppleTheme.cornerRadiusMedium, style: .continuous)
                            .stroke(RTColor.glassBorder, lineWidth: 0.5)
                    )
            )
    }
}
```

### 3. `GlassBackground`

Add to `Components.swift`:

```swift
struct GlassBackground: View {
    var body: some View {
        LinearGradient(
            colors: [RTColor.background, RTColor.surface],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}
```

### 4. Replacement rules for views

- `.background(RTColor.background.ignoresSafeArea())` → `.background(GlassBackground())`
- `.background(RTColor.surface)` + `.clipShape(RoundedRectangle(...))` → wrap in `NativeCard` or `GlassRow`
- `.background(RTColor.surfaceHighlight.opacity(0.5))` + `.clipShape(RoundedRectangle(...))` → use `GlassRow`
- `.background(RTColor.surfaceHighlight)` for selected states → use `RTColor.glassBorder` or `RTColor.glassHighlight`
- List rows with `.background(RTColor.surface)` → use `GlassRow`

---

### Task 1: Design system tokens and glass components

**Files:**
- Modify: `ReadinessTracker/Design/Theme.swift`
- Modify: `ReadinessTracker/Design/AppleNativeTheme.swift`
- Modify: `ReadinessTracker/Design/Components.swift`

**Interfaces:**
- Produces: `RTColor.glassBackground`, `glassBorder`, `glassHighlight`
- Produces: `AppleTheme.glassShadowOpacity`, `glassShadowRadius`, `glassShadowY`
- Produces: glass `NativeCard`, `GlassRow`, `GlassBackground`

- [ ] **Step 1: Add glass tokens to `Theme.swift`**

In `RTColor` add:

```swift
static let glassBackground = Color.white.opacity(0.08)
static let glassBorder = Color.white.opacity(0.12)
static let glassHighlight = Color.white.opacity(0.04)
```

- [ ] **Step 2: Add glass tokens to `AppleNativeTheme.swift`**

In `AppleTheme` add:

```swift
static let glassShadowOpacity: Double = 0.12
static let glassShadowRadius: CGFloat = 12
static let glassShadowY: CGFloat = 6
```

- [ ] **Step 3: Update `NativeCard` in `AppleNativeTheme.swift`**

Replace the body with the glass implementation from the Glass Patterns section.

- [ ] **Step 4: Update `StatGridItem` in `AppleNativeTheme.swift`**

Replace `.background(RTColor.surface)` with `.background(.ultraThinMaterial)` and add border:

```swift
.padding(16)
.background(
    RoundedRectangle(cornerRadius: AppleTheme.cornerRadiusMedium, style: .continuous)
        .fill(.ultraThinMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: AppleTheme.cornerRadiusMedium, style: .continuous)
                .stroke(RTColor.glassBorder, lineWidth: 0.5)
        )
)
```

- [ ] **Step 5: Update `NativePeriodSelector` in `AppleNativeTheme.swift`**

Replace the outer `.background(RTColor.surface)` with `.background(.ultraThinMaterial)` and keep the selection highlight using `RTColor.glassHighlight`.

- [ ] **Step 6: Update `OutlierCallout` in `AppleNativeTheme.swift`**

Replace `.background(RTColor.surface)` with `.background(.ultraThinMaterial)` and add the same border overlay as `StatGridItem`.

- [ ] **Step 7: Add `GlassRow` and `GlassBackground` to `Components.swift`**

Use the code from the Glass Patterns section.

- [ ] **Step 8: Build**

Run:

```bash
xcodebuild -project ReadinessTracker.xcodeproj -scheme ReadinessTracker -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -configuration Debug build 2>&1 | tail -20
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 9: Commit**

```bash
git add ReadinessTracker/Design/Theme.swift ReadinessTracker/Design/AppleNativeTheme.swift ReadinessTracker/Design/Components.swift
git commit -m "feat: glass design system tokens and components"
```

---

### Task 2: Core views — Dashboard, ReadinessDetail, RecoveryStrainDetail

**Files:**
- Modify: `ReadinessTracker/Views/DashboardView.swift`
- Modify: `ReadinessTracker/Views/ReadinessDetailView.swift`
- Modify: `ReadinessTracker/Views/RecoveryStrainDetailView.swift`

**Interfaces:**
- Consumes: `GlassBackground`, `NativeCard`, `GlassRow`

- [ ] **Step 1: Apply glass background to all three views**

In each view, replace `.background(RTColor.background.ignoresSafeArea())` with `.background(GlassBackground())`.

- [ ] **Step 2: Replace direct `RTColor.surface` backgrounds**

In `DashboardView`, update `journalButton`, `checkInSection` cards, and any other `.background(RTColor.surface)` + `.clipShape(...)` patterns to use `GlassRow` or `NativeCard`.

In `ReadinessDetailView` and `RecoveryStrainDetailView`, replace `.background(RTColor.surfaceHighlight.opacity(0.5))` on `ComponentRow`, `StrainRow`, `NutritionRow`, `RecoveryFactorRow`, `WorkoutRow` with `GlassRow`.

- [ ] **Step 3: Build**

Run:

```bash
xcodebuild -project ReadinessTracker.xcodeproj -scheme ReadinessTracker -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -configuration Debug build 2>&1 | tail -20
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add ReadinessTracker/Views/DashboardView.swift ReadinessTracker/Views/ReadinessDetailView.swift ReadinessTracker/Views/RecoveryStrainDetailView.swift
git commit -m "feat: glass styling for core dashboard and detail views"
```

---

### Task 3: ContentView / History / DayDetail / SleepAnalysis

**Files:**
- Modify: `ReadinessTracker/Views/ContentView.swift`
- Modify: `ReadinessTracker/Views/DayDetailView.swift`
- Modify: `ReadinessTracker/Views/SleepAnalysisView.swift`

**Interfaces:**
- Consumes: `GlassBackground`, `GlassRow`, `NativeCard`

- [ ] **Step 1: Apply glass background and glass tab bar**

In `ContentView`, set the `TabView` background to glass:

```swift
.toolbarBackground(.ultraThinMaterial, for: .tabBar)
```

In `HistoryView`, replace `.background(RTColor.background.ignoresSafeArea())` with `.background(GlassBackground())` and update `HistoryRow` background to `GlassRow`.

- [ ] **Step 2: Apply glass to `DayDetailView` and `SleepAnalysisView`**

Replace `.background(RTColor.background.ignoresSafeArea())` with `.background(GlassBackground())`. Replace `.background(RTColor.surface)` and `.background(RTColor.surfaceHighlight.opacity(0.5))` on cards/rows with `NativeCard`/`GlassRow`.

- [ ] **Step 3: Build**

Run:

```bash
xcodebuild -project ReadinessTracker.xcodeproj -scheme ReadinessTracker -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -configuration Debug build 2>&1 | tail -20
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add ReadinessTracker/Views/ContentView.swift ReadinessTracker/Views/DayDetailView.swift ReadinessTracker/Views/SleepAnalysisView.swift
git commit -m "feat: glass styling for history, day detail, and sleep views"
```

---

### Task 4: Analytics views

**Files:**
- Modify: `ReadinessTracker/Views/TrendDetailView.swift`
- Modify: `ReadinessTracker/Views/MetricDetailView.swift`
- Modify: `ReadinessTracker/Views/AdvancedMetricDetailView.swift`
- Modify: `ReadinessTracker/Views/AdvancedMetricChartView.swift`
- Modify: `ReadinessTracker/Views/SmartInsightsView.swift`
- Modify: `ReadinessTracker/Views/RecoveryTrajectoryView.swift`
- Modify: `ReadinessTracker/Views/WeeklyPatternView.swift`
- Modify: `ReadinessTracker/Views/DistributionHistogramView.swift`
- Modify: `ReadinessTracker/Views/MetricCorrelationView.swift`

**Interfaces:**
- Consumes: `GlassBackground`, `GlassRow`, `NativeCard`

- [ ] **Step 1: Apply glass background to all analytics views**

Replace `.background(RTColor.background.ignoresSafeArea())` with `.background(GlassBackground())`.

- [ ] **Step 2: Replace direct `RTColor.surface` and `RTColor.surfaceHighlight.opacity(0.5)` backgrounds**

Use `NativeCard` for cards and `GlassRow` for rows/stat items.

- [ ] **Step 3: Build**

Run:

```bash
xcodebuild -project ReadinessTracker.xcodeproj -scheme ReadinessTracker -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -configuration Debug build 2>&1 | tail -20
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add ReadinessTracker/Views/TrendDetailView.swift ReadinessTracker/Views/MetricDetailView.swift ReadinessTracker/Views/AdvancedMetricDetailView.swift ReadinessTracker/Views/AdvancedMetricChartView.swift ReadinessTracker/Views/SmartInsightsView.swift ReadinessTracker/Views/RecoveryTrajectoryView.swift ReadinessTracker/Views/WeeklyPatternView.swift ReadinessTracker/Views/DistributionHistogramView.swift ReadinessTracker/Views/MetricCorrelationView.swift
git commit -m "feat: glass styling for analytics and trend views"
```

---

### Task 5: Report and trend cards

**Files:**
- Modify: `ReadinessTracker/Views/WeeklyReportView.swift`
- Modify: `ReadinessTracker/Views/QuickTrendCard.swift`
- Modify: `ReadinessTracker/Views/StrainRecoveryBalanceCard.swift`

**Interfaces:**
- Consumes: `GlassBackground`, `NativeCard`

- [ ] **Step 1: Apply glass background**

Replace `.background(RTColor.background.ignoresSafeArea())` with `.background(GlassBackground())` in `WeeklyReportView`.

- [ ] **Step 2: Update cards**

In `WeeklyReportView`, update `StatGridItem` usage (already glass from Task 1). In `QuickTrendCard` and `StrainRecoveryBalanceCard`, ensure `NativeCard` is used (automatically glass).

- [ ] **Step 3: Build**

Run:

```bash
xcodebuild -project ReadinessTracker.xcodeproj -scheme ReadinessTracker -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -configuration Debug build 2>&1 | tail -20
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add ReadinessTracker/Views/WeeklyReportView.swift ReadinessTracker/Views/QuickTrendCard.swift ReadinessTracker/Views/StrainRecoveryBalanceCard.swift
git commit -m "feat: glass styling for weekly report and trend cards"
```

---

### Task 6: WhoopFeatures cards

**Files:**
- Modify: `ReadinessTracker/Views/WhoopFeatures/StrainRecoveryWheel.swift`
- Modify: `ReadinessTracker/Views/WhoopFeatures/SleepStageBreakdown.swift`
- Modify: `ReadinessTracker/Views/WhoopFeatures/SleepQualityTrend.swift`
- Modify: `ReadinessTracker/Views/WhoopFeatures/SleepPerformanceScore.swift`
- Modify: `ReadinessTracker/Views/WhoopFeatures/SleepHRVCard.swift`
- Modify: `ReadinessTracker/Views/WhoopFeatures/SleepDisturbanceTracker.swift`
- Modify: `ReadinessTracker/Views/WhoopFeatures/SleepDebtCalculator.swift`
- Modify: `ReadinessTracker/Views/WhoopFeatures/SleepConsistencyTracker.swift`
- Modify: `ReadinessTracker/Views/WhoopFeatures/SkinTemperatureCard.swift`
- Modify: `ReadinessTracker/Views/WhoopFeatures/RespiratoryRateCard.swift`
- Modify: `ReadinessTracker/Views/WhoopFeatures/JournalEntryView.swift`

**Interfaces:**
- Consumes: `NativeCard`, `GlassRow`

- [ ] **Step 1: Apply glass styling to each card**

Replace `.background(RTColor.surface)` and `.background(RTColor.surfaceHighlight.opacity(0.5))` with `NativeCard` or `GlassRow` as appropriate. Keep existing layout and data logic.

- [ ] **Step 2: Build**

Run:

```bash
xcodebuild -project ReadinessTracker.xcodeproj -scheme ReadinessTracker -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -configuration Debug build 2>&1 | tail -20
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add ReadinessTracker/Views/WhoopFeatures/
git commit -m "feat: glass styling for WHOOP feature cards"
```

---

### Task 7: Forms and status views

**Files:**
- Modify: `ReadinessTracker/Views/JournalView.swift`
- Modify: `ReadinessTracker/Views/CheckInView.swift`
- Modify: `ReadinessTracker/Views/BreathingView.swift`
- Modify: `ReadinessTracker/Views/SyncStatusView.swift`

**Interfaces:**
- Consumes: `GlassBackground`, `NativeCard`, `GlassRow`

- [ ] **Step 1: Apply glass background and cards**

Replace `.background(RTColor.background.ignoresSafeArea())` with `.background(GlassBackground())`. Replace `.background(RTColor.surface)` and `.background(RTColor.surfaceHighlight.opacity(0.5))` with `NativeCard`/`GlassRow`.

- [ ] **Step 2: Build**

Run:

```bash
xcodebuild -project ReadinessTracker.xcodeproj -scheme ReadinessTracker -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -configuration Debug build 2>&1 | tail -20
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add ReadinessTracker/Views/JournalView.swift ReadinessTracker/Views/CheckInView.swift ReadinessTracker/Views/BreathingView.swift ReadinessTracker/Views/SyncStatusView.swift
git commit -m "feat: glass styling for journal, check-in, breathing, and sync views"
```

---

### Task 8: Final verification

**Files:**
- All touched files

- [ ] **Step 1: Run full test suite**

Run:

```bash
xcodebuild -project ReadinessTracker.xcodeproj -scheme ReadinessTracker -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -configuration Debug test 2>&1 | tail -40
```

Expected: `** TEST SUCCEEDED **` with all 38 tests passing.

- [ ] **Step 2: Check git status**

Run:

```bash
git status --short
```

Expected: working tree clean (all changes committed).

- [ ] **Step 3: Search for remaining direct `RTColor.surface` usage outside design system**

Run:

```bash
rg "RTColor\.surface" ReadinessTracker/Views/ --no-heading
```

Expected: no matches (or only intentional non-card usages).

- [ ] **Step 4: Update `progress.md`**

Append a new entry noting the glassy UI redesign is complete and all tests pass.

---

## Self-Review

**Spec coverage:**
- Glass tokens and components → Task 1
- Core views → Task 2
- Content/History/DayDetail/Sleep → Task 3
- Analytics views → Task 4
- Report/trend cards → Task 5
- WhoopFeatures → Task 6
- Forms → Task 7
- Final verification → Task 8

**Placeholder scan:** No TBD/TODO. All code snippets are concrete.

**Type consistency:**
- `NativeCard` keeps the same generic signature.
- `GlassRow` and `GlassBackground` are new, non-generic.
- `GlassCard` continues to delegate to `NativeCard`, so existing callers upgrade automatically.
