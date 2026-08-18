> I'm using the writing-plans skill to create the implementation plan.

# Apple Health Native UI Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Convert the entire app to Apple Health / Apple Fitness visual language while keeping every feature, data flow, and navigation path intact.

**Architecture:** Rebuild the design system in `ReadinessTracker/Design/` to Apple Health patterns: solid `NativeCard` with soft shadow and subtle top highlight, `AppIconTile`, `AppListRow`, `AppSectionHeader`, `AppSegmentedControl`, `AppStatPill`, `AppButton`, and `AppBackground`. Then update every view to use these components, removing all glassmorphism materials.

**Tech Stack:** Swift 5, SwiftUI, Charts, XCTest

## Global Constraints
- iOS deployment target: 16.0+
- No new third-party dependencies
- Keep all data local (UserDefaults / HealthKit)
- No persisted model changes
- All existing unit tests must pass
- Keep all features, navigation, and data flow intact

---

## File Map

| File | Responsibility |
|------|----------------|
| `ReadinessTracker/Design/Theme.swift` | Apple Health tokens |
| `ReadinessTracker/Design/AppleNativeTheme.swift` | `NativeCard`, `AppSectionHeader`, `AppSegmentedControl`, `AppStatPill`, `AppButton` |
| `ReadinessTracker/Design/Components.swift` | `AppBackground`, `AppIconTile`, `AppListRow`; keep existing helpers |
| `ReadinessTracker/Views/DashboardView.swift` | Apple Health dashboard |
| `ReadinessTracker/Views/ReadinessDetailView.swift` | Apple Health detail |
| `ReadinessTracker/Views/RecoveryStrainDetailView.swift` | Apple Health recovery/strain |
| `ReadinessTracker/Views/ContentView.swift` | Apple Health tab bar + history |
| `ReadinessTracker/Views/DayDetailView.swift` | Apple Health day detail |
| `ReadinessTracker/Views/SleepAnalysisView.swift` | Apple Health sleep |
| `ReadinessTracker/Views/TrendDetailView.swift` | Apple Health trends |
| `ReadinessTracker/Views/MetricDetailView.swift` | Apple Health metric detail |
| `ReadinessTracker/Views/AdvancedMetricDetailView.swift` | Apple Health advanced metric |
| `ReadinessTracker/Views/AdvancedMetricChartView.swift` | Apple Health chart card |
| `ReadinessTracker/Views/SmartInsightsView.swift` | Apple Health insights |
| `ReadinessTracker/Views/RecoveryTrajectoryView.swift` | Apple Health trajectory |
| `ReadinessTracker/Views/WeeklyPatternView.swift` | Apple Health weekly pattern |
| `ReadinessTracker/Views/DistributionHistogramView.swift` | Apple Health histogram |
| `ReadinessTracker/Views/MetricCorrelationView.swift` | Apple Health correlation |
| `ReadinessTracker/Views/WeeklyReportView.swift` | Apple Health weekly report |
| `ReadinessTracker/Views/QuickTrendCard.swift` | Apple Health quick trend |
| `ReadinessTracker/Views/StrainRecoveryBalanceCard.swift` | Apple Health balance |
| `ReadinessTracker/Views/JournalView.swift` | Apple Health journal |
| `ReadinessTracker/Views/CheckInView.swift` | Apple Health check-in |
| `ReadinessTracker/Views/BreathingView.swift` | Apple Health breathing |
| `ReadinessTracker/Views/SyncStatusView.swift` | Apple Health sync status |
| `ReadinessTracker/Views/WhoopFeatures/*.swift` | Apple Health WHOOP cards |

---

## Apple Health Patterns (use these in every task)

### 1. `AppBackground`

Add to `Components.swift`:

```swift
struct AppBackground: View {
    var body: some View {
        LinearGradient(
            colors: [Color.black, RTColor.background],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}
```

### 2. `NativeCard` (Apple Health solid card)

Replace the current glass `NativeCard` body in `AppleNativeTheme.swift` with:

```swift
struct NativeCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(AppleTheme.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: AppleTheme.cornerRadiusLarge, style: .continuous)
                    .fill(RTColor.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppleTheme.cornerRadiusLarge, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.03), .clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
                    .shadow(color: .black.opacity(AppleTheme.cardShadowOpacity), radius: AppleTheme.cardShadowRadius, x: 0, y: AppleTheme.cardShadowY)
            )
    }
}
```

### 3. `AppIconTile`

Add to `Components.swift`:

```swift
struct AppIconTile: View {
    let systemName: String
    let color: Color
    var size: CGFloat = 32

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size * 0.44, weight: .semibold))
            .foregroundStyle(color)
            .frame(width: size, height: size)
            .background(color.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
```

### 4. `AppListRow`

Add to `Components.swift`:

```swift
struct AppListRow: View {
    let icon: String
    let color: Color
    let label: String
    let value: String
    var showChevron: Bool = true

    var body: some View {
        HStack(spacing: 12) {
            AppIconTile(systemName: icon, color: color)
            Text(label)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(RTColor.secondaryText)
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RTColor.tertiaryText)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: AppleTheme.cornerRadiusMedium, style: .continuous)
                .fill(RTColor.surface)
        )
    }
}
```

### 5. `AppSectionHeader`

Add to `AppleNativeTheme.swift`:

```swift
struct AppSectionHeader: View {
    let title: String
    var action: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(AppleTheme.sectionHeader)
                .foregroundStyle(.white)
            Spacer()
            if let action {
                Button(action: action) {
                    HStack(spacing: 4) {
                        Text("See All")
                            .font(.subheadline.weight(.medium))
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(RTColor.secondaryText)
                }
            }
        }
    }
}
```

### 6. `AppSegmentedControl`

Add to `AppleNativeTheme.swift`:

```swift
struct AppSegmentedControl<Option: Hashable>: View {
    let options: [Option]
    @Binding var selection: Option
    let label: (Option) -> String

    var body: some View {
        HStack(spacing: 4) {
            ForEach(options, id: \.self) { option in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selection = option
                    }
                } label: {
                    Text(label(option))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(selection == option ? .white : RTColor.secondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background {
                            if selection == option {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(RTColor.surfaceHighlight)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(RTColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppleTheme.cornerRadiusSmall, style: .continuous))
    }
}
```

### 7. `AppStatPill`

Add to `AppleNativeTheme.swift`:

```swift
struct AppStatPill: View {
    let label: String
    let value: String
    let unit: String
    let color: Color
    let trend: TrendDirection?

    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)\(unit)")
                .font(AppleTheme.cardValue)
                .foregroundStyle(color)
                .monospacedDigit()
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(RTColor.secondaryText)
            if let trend {
                CompactTrendIndicator(direction: trend, percentChange: nil)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(RTColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppleTheme.cornerRadiusMedium, style: .continuous))
    }
}
```

### 8. `AppButton`

Add to `AppleNativeTheme.swift`:

```swift
struct AppButton: View {
    let title: String
    let systemImage: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .padding()
                .frame(maxWidth: .infinity)
                .background(color)
                .foregroundStyle(.black)
                .clipShape(RoundedRectangle(cornerRadius: AppleTheme.cornerRadiusMedium, style: .continuous))
        }
    }
}
```

### 9. Replacement rules for views

- `.background(GlassBackground())` → `.background(AppBackground())`
- `.background(RTColor.background.ignoresSafeArea())` → `.background(AppBackground())`
- `GlassRow { ... }` → `AppListRow(...)` where the row has icon + label + value; otherwise wrap content in `NativeCard`
- `.background(.ultraThinMaterial)` on selectors → use `AppSegmentedControl` or keep `RTColor.surface` solid background
- Remove all uses of `RTColor.glassBorder`, `RTColor.glassHighlight`, `RTColor.glassBackground`
- Tab bar: keep `.toolbarBackground(.ultraThinMaterial, for: .tabBar)` or use `.toolbarBackground(RTColor.surface, for: .tabBar)` for solid Apple Health look

---

### Task 1: Design system tokens and components

**Files:**
- Modify: `ReadinessTracker/Design/Theme.swift`
- Modify: `ReadinessTracker/Design/AppleNativeTheme.swift`
- Modify: `ReadinessTracker/Design/Components.swift`

**Interfaces:**
- Produces: `AppBackground`, `AppIconTile`, `AppListRow`
- Produces: `AppSectionHeader`, `AppSegmentedControl`, `AppStatPill`, `AppButton`
- Produces: solid `NativeCard`

- [ ] **Step 1: Add tokens to `Theme.swift`**

Remove glass tokens (`glassBackground`, `glassBorder`, `glassHighlight`). Add:

```swift
static let appBackgroundTop = Color.black
static let appBackgroundBottom = RTColor.background
```

- [ ] **Step 2: Add tokens to `AppleNativeTheme.swift`**

Replace glass shadow tokens with:

```swift
static let cardShadowOpacity: Double = 0.15
static let cardShadowRadius: CGFloat = 8
static let cardShadowY: CGFloat = 4
```

- [ ] **Step 3: Update `NativeCard`**

Replace the body with the Apple Health solid card implementation from the Patterns section.

- [ ] **Step 4: Add `AppSectionHeader`, `AppSegmentedControl`, `AppStatPill`, `AppButton`**

Add the exact components from the Patterns section to `AppleNativeTheme.swift`.

- [ ] **Step 5: Update `StatGridItem`**

Replace the glass background with the solid card pattern:

```swift
.padding(16)
.background(
    RoundedRectangle(cornerRadius: AppleTheme.cornerRadiusMedium, style: .continuous)
        .fill(RTColor.surface)
)
```

- [ ] **Step 6: Update `NativePeriodSelector`**

Replace `.background(.ultraThinMaterial)` with `.background(RTColor.surface)` and selection fill with `RTColor.surfaceHighlight`.

- [ ] **Step 7: Update `OutlierCallout`**

Replace glass background with solid `RTColor.surface` and remove border.

- [ ] **Step 8: Add `AppBackground`, `AppIconTile`, `AppListRow` to `Components.swift`**

Add the exact components from the Patterns section. Remove `GlassRow` and `GlassBackground` (or keep `GlassCard` delegating to `NativeCard` for backward compatibility).

- [ ] **Step 9: Build**

Run:

```bash
xcodebuild -project ReadinessTracker.xcodeproj -scheme ReadinessTracker -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -configuration Debug build 2>&1 | tail -20
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 10: Commit**

```bash
git add ReadinessTracker/Design/Theme.swift ReadinessTracker/Design/AppleNativeTheme.swift ReadinessTracker/Design/Components.swift
git commit -m "feat: Apple Health design system tokens and components"
```

---

### Task 2: Core views — Dashboard, ReadinessDetail, RecoveryStrainDetail

**Files:**
- Modify: `ReadinessTracker/Views/DashboardView.swift`
- Modify: `ReadinessTracker/Views/ReadinessDetailView.swift`
- Modify: `ReadinessTracker/Views/RecoveryStrainDetailView.swift`

**Interfaces:**
- Consumes: `AppBackground`, `NativeCard`, `AppListRow`, `AppSectionHeader`

- [ ] **Step 1: Apply `AppBackground`**

Replace `.background(GlassBackground())` or `.background(RTColor.background.ignoresSafeArea())` with `.background(AppBackground())`.

- [ ] **Step 2: Replace `GlassRow` with `AppListRow`**

In `RecoveryStrainDetailView`, convert `StrainRow`, `NutritionRow`, `RecoveryFactorRow`, `WorkoutRow` to use `AppListRow` with appropriate icons/colors.

In `DashboardView`, update `journalButton`, `checkInSection` cards, and WHOOP section rows to use `NativeCard`/`AppListRow`.

In `ReadinessDetailView`, convert `ComponentRow` to use `AppListRow`.

- [ ] **Step 3: Remove glass tokens**

Remove any uses of `RTColor.glassBorder`, `RTColor.glassHighlight`, `RTColor.glassBackground` in these files.

- [ ] **Step 4: Build**

Run:

```bash
xcodebuild -project ReadinessTracker.xcodeproj -scheme ReadinessTracker -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -configuration Debug build 2>&1 | tail -20
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git add ReadinessTracker/Views/DashboardView.swift ReadinessTracker/Views/ReadinessDetailView.swift ReadinessTracker/Views/RecoveryStrainDetailView.swift
git commit -m "feat: Apple Health styling for core dashboard and detail views"
```

---

### Task 3: ContentView / History / DayDetail / SleepAnalysis

**Files:**
- Modify: `ReadinessTracker/Views/ContentView.swift`
- Modify: `ReadinessTracker/Views/DayDetailView.swift`
- Modify: `ReadinessTracker/Views/SleepAnalysisView.swift`

**Interfaces:**
- Consumes: `AppBackground`, `AppListRow`, `NativeCard`

- [ ] **Step 1: Apply `AppBackground` and solid tab bar**

In `ContentView`, change tab bar background to `.toolbarBackground(RTColor.surface, for: .tabBar)`.

In `HistoryView`, replace `GlassBackground()` with `AppBackground()` and update history rows to use `AppListRow` (icon: calendar, color: RTColor.optimal, label: formatted date, value: score).

- [ ] **Step 2: Apply Apple Health patterns to `DayDetailView` and `SleepAnalysisView`**

Replace `GlassBackground()` with `AppBackground()`. Replace `GlassRow` with `AppListRow` or `NativeCard`. Remove glass tokens.

- [ ] **Step 3: Build**

Run:

```bash
xcodebuild -project ReadinessTracker.xcodeproj -scheme ReadinessTracker -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -configuration Debug build 2>&1 | tail -20
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add ReadinessTracker/Views/ContentView.swift ReadinessTracker/Views/DayDetailView.swift ReadinessTracker/Views/SleepAnalysisView.swift
git commit -m "feat: Apple Health styling for history, day detail, and sleep views"
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
- Consumes: `AppBackground`, `AppListRow`, `NativeCard`, `AppSegmentedControl`

- [ ] **Step 1: Apply `AppBackground` to all analytics views**

Replace `GlassBackground()` with `AppBackground()`.

- [ ] **Step 2: Replace `GlassRow` and glass tokens**

Convert rows to `AppListRow` or `NativeCard`. Replace glass selector backgrounds with solid `RTColor.surface`. Remove glass tokens.

- [ ] **Step 3: Build**

Run:

```bash
xcodebuild -project ReadinessTracker.xcodeproj -scheme ReadinessTracker -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -configuration Debug build 2>&1 | tail -20
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add ReadinessTracker/Views/TrendDetailView.swift ReadinessTracker/Views/MetricDetailView.swift ReadinessTracker/Views/AdvancedMetricDetailView.swift ReadinessTracker/Views/AdvancedMetricChartView.swift ReadinessTracker/Views/SmartInsightsView.swift ReadinessTracker/Views/RecoveryTrajectoryView.swift ReadinessTracker/Views/WeeklyPatternView.swift ReadinessTracker/Views/DistributionHistogramView.swift ReadinessTracker/Views/MetricCorrelationView.swift
git commit -m "feat: Apple Health styling for analytics and trend views"
```

---

### Task 5: Report and trend cards

**Files:**
- Modify: `ReadinessTracker/Views/WeeklyReportView.swift`
- Modify: `ReadinessTracker/Views/QuickTrendCard.swift`
- Modify: `ReadinessTracker/Views/StrainRecoveryBalanceCard.swift`

**Interfaces:**
- Consumes: `AppBackground`, `NativeCard`, `AppStatPill`

- [ ] **Step 1: Apply `AppBackground`**

Replace `GlassBackground()` with `AppBackground()` in `WeeklyReportView`.

- [ ] **Step 2: Update cards to Apple Health style**

Use `NativeCard` and `AppStatPill` for stat grids. Remove glass tokens.

- [ ] **Step 3: Build**

Run:

```bash
xcodebuild -project ReadinessTracker.xcodeproj -scheme ReadinessTracker -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -configuration Debug build 2>&1 | tail -20
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add ReadinessTracker/Views/WeeklyReportView.swift ReadinessTracker/Views/QuickTrendCard.swift ReadinessTracker/Views/StrainRecoveryBalanceCard.swift
git commit -m "feat: Apple Health styling for weekly report and trend cards"
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
- Consumes: `NativeCard`, `AppListRow`, `AppIconTile`

- [ ] **Step 1: Apply Apple Health patterns to each card**

Replace `GlassRow` with `AppListRow` or solid `RTColor.surface` rows. Remove glass tokens. Keep existing layout and data logic.

- [ ] **Step 2: Build**

Run:

```bash
xcodebuild -project ReadinessTracker.xcodeproj -scheme ReadinessTracker -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -configuration Debug build 2>&1 | tail -20
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add ReadinessTracker/Views/WhoopFeatures/
git commit -m "feat: Apple Health styling for WHOOP feature cards"
```

---

### Task 7: Forms and status views

**Files:**
- Modify: `ReadinessTracker/Views/JournalView.swift`
- Modify: `ReadinessTracker/Views/CheckInView.swift`
- Modify: `ReadinessTracker/Views/BreathingView.swift`
- Modify: `ReadinessTracker/Views/SyncStatusView.swift`

**Interfaces:**
- Consumes: `AppBackground`, `NativeCard`, `AppListRow`, `AppButton`

- [ ] **Step 1: Apply `AppBackground` and Apple Health rows**

Replace `GlassBackground()` with `AppBackground()`. Replace `GlassRow` with `AppListRow` or solid `RTColor.surface` rows. Use `AppButton` for primary actions. Remove glass tokens.

- [ ] **Step 2: Build**

Run:

```bash
xcodebuild -project ReadinessTracker.xcodeproj -scheme ReadinessTracker -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -configuration Debug build 2>&1 | tail -20
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add ReadinessTracker/Views/JournalView.swift ReadinessTracker/Views/CheckInView.swift ReadinessTracker/Views/BreathingView.swift ReadinessTracker/Views/SyncStatusView.swift
git commit -m "feat: Apple Health styling for journal, check-in, breathing, and sync views"
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

- [ ] **Step 3: Search for remaining glassmorphism usage**

Run:

```bash
rg "ultraThinMaterial|glassBorder|glassHighlight|glassBackground|GlassRow|GlassBackground" ReadinessTracker/ --no-heading
```

Expected: no matches except `GlassCard` delegating to `NativeCard` (if kept).

- [ ] **Step 4: Update `progress.md`**

Append a new entry noting the Apple Health UI redesign is complete and all tests pass.

---

## Self-Review

**Spec coverage:**
- Design system tokens and components → Task 1
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
- `AppListRow` has `icon`, `color`, `label`, `value`, `showChevron`.
- `AppSegmentedControl` is generic over `Option: Hashable`.
- `AppStatPill` takes `label`, `value`, `unit`, `color`, `trend`.
- `AppButton` takes `title`, `systemImage`, `color`, `action`.
