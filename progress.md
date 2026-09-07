# Progress

## 2026-09-08 — Weekly Report surface capture (Status-table gap)

- Added `testWeeklyReportSurface` to open History → Weekly Report sheet and save `verify-weekly-report.png` (report chrome under `-ui-fixture`).
- Wired the new PNG through `capture-surfaces.sh` and `ci-guard-tree.sh`; committed `.audit/verify-weekly-report.png`.
- README Status + App surfaces + Honest gaps: Weekly Report sheet shipped with evidence (post Sleep disturbance).
- Branch: `feature/weekly-report-surface-capture`.





## 2026-09-08 — Sleep disturbance surface capture (Status-table gap)

- Added `testSleepDisturbanceSurfaceVisibleAfterScroll` to scroll Today to Sleep Stages / “Sleep disturbances” and save `verify-sleep-disturbances.png`.
- Wired the new PNG through `capture-surfaces.sh` and `ci-guard-tree.sh`; committed `.audit/verify-sleep-disturbances.png`.
- README Status + App surfaces + Honest gaps: Sleep disturbance count shipped with evidence (post Journal).
- Branch: `feature/sleep-disturbance-surface-capture`.




## 2026-09-08 — Journal surface capture (Status-table gap)

- Added `testJournalSurface` to open Journal from Today’s NavigationLink and save `verify-journal.png` (Log 7 days strip).
- Wired the new PNG through `capture-surfaces.sh` and `ci-guard-tree.sh`; committed `.audit/verify-journal.png`.
- README Status + App surfaces + Honest gaps: Journal strip shipped with evidence (post History).
- Branch: `feature/journal-surface-capture`.





## 2026-09-08 — History tab surface capture (Status-table gap)

- Added `testHistoryTabSurface` to open the History tab (Weekly Report + Trends + source picker) and save `verify-history.png`.
- Wired the new PNG through `capture-surfaces.sh` and `ci-guard-tree.sh`; committed `.audit/verify-history.png`.
- README Status + App surfaces + Honest gaps: History tab shipped with evidence (post Check-in).
- Branch: `feature/history-surface-capture`.




## 2026-09-07 — Check-in tab surface capture (Status-table gap)

- Added `testCheckInTabSurface` to open the Check-in tab (Morning/Evening picker + Save) and save `verify-checkin.png`.
- Wired the new PNG through `capture-surfaces.sh` and `ci-guard-tree.sh`; committed `.audit/verify-checkin.png`.
- README Status + App surfaces + Honest gaps: Check-in tab shipped with evidence (post Sleep Debt).
- Branch: `feature/checkin-surface-capture`.



## 2026-09-07 — Sleep debt surface capture (Status-table gap)

- Added `testSleepDebtSurfaceVisibleAfterScroll` to scroll Today to Sleep Debt and save `verify-sleep-debt.png`.
- Wired the new PNG through `capture-surfaces.sh` and `ci-guard-tree.sh`; committed `.audit/verify-sleep-debt.png`.
- README Status + App surfaces + Honest gaps: Sleep Debt shipped with evidence (post Honest #1–#3).
- Branch: `feature/sleep-debt-surface-capture`.


## 2026-09-07 — Self-hosted Mac mini CI

- Registered `mac-mini` runner (labels `self-hosted,macOS,ARM64`); pointed `ios-tests` / `ios-ui` at it; docs in `docs/SELF_HOSTED_RUNNER.md`.


## 2026-09-07 — Triple-ring READY hole (Honest gap #3)

- Verified center “90 READY” was overlay-only (did not set radius); hole was ~61% of outer from `lineWidth=14` / `gap=4`.
- Packed rings toward Fitness Summary: `lineWidth = size/10`, `gap=2`, kept #15 concentric diameters; scaled center score + READY to fit the smaller hole.
- Recaptured `verify-rings.png`; README Status + Honest gaps (gap #3 closed).
- Branch: `feature/triple-ring-ready-hole`.

## 2026-09-07 — Sleep quality surface capture (Honest gap #1)

- Added `testSleepQualitySurfaceVisibleAfterScroll` to scroll Today to Sleep Quality Trend + Sleep Consistency and save `verify-sleep-quality.png`.
- Wired the new PNG through `capture-surfaces.sh` and `ci-guard-tree.sh`; committed `.audit/verify-sleep-quality.png`.
- README Status + Honest gaps: gap #1 closed with evidence; gap #3 (READY hole) remains.
- Branch: `feature/sleep-quality-surface-capture`.


## 2026-09-07 — Check-in card no-wrap (Honest gap #2)

- Fixed `CheckInStatusCard` so Morning/Evening labels + Done/Pending stay on one line on half-width HStack cards (`lineLimit(1)`, `minimumScaleFactor(0.75)`, tighter spacing).
- Updated README Status / Body caption / Honest gaps (gap #2 closed; #1 and #3 remain).
- Gates: `./scripts/ci-guard-tree.sh`, `ci-verify.sh`, prefer `capture-surfaces.sh` for verify-body-activity.png.
- Branch: `feature/checkin-card-no-wrap`.


## 2026-07-12 — Phase 1 verification + Phase 2 scoping

- Re-ran full test suite on `feature/whoop-strain-recovery-model`.
- Result: **TEST SUCCEEDED** — 5 tests, 0 failures.
- Read current `DashboardView.swift`, `RecoveryStrainDetailView.swift`, approved Phase 1 plan/design.
- Updated `task_plan.md` with Phase 1 completion and proposed Phase 2 options.

## 2026-07-12 — Phase 2A design (RMSSD)

- User approved doing all four phases in order 2A → 2B → 2C → 2D.
- User approved Approach A: heartbeat-series RMSSD.
- Read `HealthKitManager.swift`, `RecoveryCalculator.swift`, `HealthData.swift`, `HRVFrequencyAnalysis.swift`.
- Wrote `docs/superpowers/specs/2026-07-12-rmssd-design.md`.
- Spec self-review: fixed heartbeat-series RR extraction to compute differences between cumulative timestamps and discard gaps.

## 2026-07-13 — Phase 2A implementation complete

- Subagent-driven development executed all 7 implementation tasks + final verification.
- Final review found mixed HRV baseline issue; fixed by filtering `BaselineManager.hrvBaseline` by `hrvIsRMSSD` with fallback.
- Added `BaselineManagerTests` for RMSSD/SDNN baseline filtering.
- Final test run: **TEST SUCCEEDED** — 12 tests, 0 failures.
- Phase 2A complete.

## 2026-07-13 — Phase 2B design + implementation (workout-level strain)

- Wrote `docs/superpowers/specs/2026-07-13-workout-strain-design.md`.
- Wrote `docs/superpowers/plans/2026-07-13-workout-strain-implementation-plan.md`.
- Subagent-driven development executed 7 implementation tasks.
- Task 3 review found missing test for `trimp(for:using:)`; added via fix subagent.
- Final review found: HRV fallback should be 0, missing `enrichSessions`, history-aware score inconsistency, contribution scaling by daily strain, duration fallback. All fixed via fix subagents.
- Final test run: **TEST SUCCEEDED** — 21 tests, 0 failures.
- Phase 2B complete; ready for Phase 2C design.

## 2026-07-13 — Phase 2C design (SpO2 + nutrition + menstrual cycle)

- Design spec and implementation plan written.
- Planning docs committed: 77e0aef.

## 2026-07-15 — Phase 2C implementation complete

- Subagent-driven development executed Tasks 1-8 + final verification.
- Fixes applied: target membership (Task 2), historical `hasData` guard (Task 5), readiness weight integration (Task 6), UserSettings teardown (Task 8), menstrual penalty in `ReadinessCalculator`, SpO2 display normalization, `.bloodOxygen` `MetricType` case (final review).
- Final test run: **TEST SUCCEEDED** — 26 tests, 0 failures.
- Head: abb4e3d.

## 2026-07-15 — Phase 2D implementation complete

- Design spec and implementation plan written and committed.
- Subagent-driven development executed Tasks 1-5 + final verification.
- Added `StrainRecoveryBalance`, Dashboard/recovery balance card, `WeeklyReportView`, strain/workout AI rules, and `QuickTrendCard` 7/30/90-day row.
- Final test run: **TEST SUCCEEDED** — 38 tests, 0 failures.
- Head: a78d5a2.

## 2026-08-01 — Glassy UI redesign complete

- New branch `feature/glassy-ui-redesign`.
- Design system updated: glass tokens, `NativeCard` → `.ultraThinMaterial`, `GlassRow`, `GlassBackground`.
- All views updated via AgentSwarm: Dashboard, detail views, history, sleep, analytics, weekly report, trend cards, WHOOP features, journal, check-in, breathing, sync status.
- Final test run: **TEST SUCCEEDED** — 38 tests, 0 failures.
- Head: f3f00f3.

## 2026-08-01 — Apple Health native UI redesign complete

- Design system rebuilt to Apple Health patterns: solid `NativeCard`, `AppBackground`, `AppIconTile`, `AppListRow`, `AppSectionHeader`, `AppSegmentedControl`, `AppStatPill`, `AppButton`.
- All 33 view files converted via AgentSwarm.
- Glassmorphism remnants removed.
- Final test run: **TEST SUCCEEDED** — 38 tests, 0 failures.
- Head: 4993fd8.

## 2026-07-14 — Phase 2C final whole-branch review fixes

- Applied menstrual readiness penalty in `ReadinessCalculator.calculateBreakdown` (mirrors `RecoveryCalculator`).
- Normalized legacy SpO2 fraction display in `ReadinessDetailView` SpO2 `ComponentRow`.
- Added `.bloodOxygen` case to `MetricType` with icon, unit, color, zones, and `higherIsBetter`.
- Updated SpO2 `BreakdownBar` to use `metricType: .bloodOxygen`.
- Fixed exhaustive `switch metric` statements across views/engine after new case addition.
- Removed redundant `trackMenstrualCycle` reset in `testMenstrualAdjustment` (teardown already covers it).
- Build: **BUILD SUCCEEDED**.
- Tests: **TEST SUCCEEDED** — 26 tests, 0 failures.
- Committed: `fix: final review — menstrual readiness penalty, SpO2 display, bloodOxygen MetricType`.

## 2026-07-14 — Phase 2D Task 2: strain/recovery balance card

- Added `DualReadinessScores.balance` in `ReadinessCalculator.swift`.
- Created `StrainRecoveryBalanceCard.swift` and added it to the app target.
- Wired card into `DashboardView.whoopSection` and `RecoveryStrainDetailView` (replacing inline indicator + adding 7-day balance chart section).
- Build: **BUILD SUCCEEDED**.
- Committed: `feat: expose strain/recovery balance card in Dashboard and detail` (68912f7).
- Report written to `.superpowers/sdd/task-2-report.md`.

## 2026-07-15 — Phase 2D final whole-branch review fixes

- Applied quick-trend prior-window fix (180-day `longHistory`) in `DashboardView.swift`.
- Added `recommendationsSection` showing top 2 `AIRecommendationEngine` recommendations in `DashboardView.swift`.
- Deduplicated AI recommendations by title with `uniqueByTitle()` in `AIRecommendations.swift`.
- Fixed 7-Day Balance chart to use `history.suffix(7)` in `RecoveryStrainDetailView.swift`.
- Fixed weekly report `avgRPE` to average only valid RPE values.
- Fixed weekly report `avgReadiness` to use history-aware `ReadinessCalculator.calculateBreakdown(...).totalScore`.
- Build: **BUILD SUCCEEDED**.
- Tests: **TEST SUCCEEDED** — 38 tests, 0 failures.
- Committed: `fix: final review — quick-trend window, AI UI, dedupe, report math` (a78d5a2).
- Report written to `.superpowers/sdd/final-fix-report.md`.

## 2026-07-14 — Phase 2D Task 3: WeeklyReportView + wiring

- Added `avgStrain` to `WeeklyReport` and `WeeklyReportGenerator`.
- Created `WeeklyReportView.swift` and added it to the app target.
- Wired `WeeklyReportView` from `DashboardView` (toolbar button + sheet).
- Wired `WeeklyReportView` from `HistoryView` (top-row button + sheet).
- Added `WeeklyReportGenerator.swift` to the app target; marked generator `@MainActor`.
- Made `TrendDirection` conform to `Codable`.
- Build: **BUILD SUCCEEDED**.
- Tests: **TEST SUCCEEDED** — 31 tests, 0 failures.
- Committed: `feat: add WeeklyReportView and wire from Dashboard and History` (265b9b1).
- Report written to `.superpowers/sdd/task-3-report.md`.

## 2026-08-02 — Post-merge audit and bug fixes

- AgentSwarm audited theme and features across all views/models.
- Fixed: BreathingView added to target + `BreathingStatItem` rename; journal entries persisted; check-in pre-population + save confirmation + time-of-day scoped saves; real sleep stage data in Dashboard/DayDetail/SleepAnalysis; breakdown weights match ReadinessCalculator + SpO2 row; ReadinessDetailView source/SpO2 normalization; fallback strain breakdown reconciled; MetricDetailView trend inversion; MetricCorrelationView trend line + nil SpO2; QuickTrendCard nil SpO2 + prior window; WeeklyReportView trend indicator; SleepConsistencyTracker midnight wrap; BaselineManager consistencyScore uses sleepStartTime; AIRecommendations Rule 5 guard; dead See All buttons; AnimatedNumber zero crash; AppBackground consistency; AdvancedMetricDetailView wired into navigation.
- Final test run: **TEST SUCCEEDED** — 38 tests, 0 failures.
- Head: 0bb50db.

## 2026-08-25 — AgentSwarm UI/UX + features (8 workstreams)

- Wave 1 (7 parallel agents): design-system polish (contrast, Dynamic Type, VoiceOver, AppleTheme canonical), dashboard redesign (hero, shimmer loading, error banner, auto-load), navigation/empty states, smart notifications (NotificationManager + settings UI, quiet hours), watch companion app (WatchConnectivity, 3 pages + Crown check-in), home-screen widget (target, App Group, WidgetDataExporter), coaching feed (CoachingEngine + CoachingView + 6 tests).
- Wave 2: integrator wired cross-file seams (pushSnapshot+widget export in DataStore.persist, dark scheme, sheet Done buttons); micro-interactions sweep (haptics, staggered slideIn, Reduce Motion support, chart tap-to-inspect).
- Final verification: TEST SUCCEEDED — 58 tests, 0 failures.
- Note: user committed mid-run as 85c6f2e; working tree still has uncommitted changes. App Group `group.com.readinesstracker` needs Apple Developer portal registration for device builds.

## 2026-09-04 — Bright Apple Health design

- Switched app to `.preferredColorScheme(.light)`.
- Redesigned `RTColor` for Apple Health light surfaces (#F2F2F7 / white cards / dark labels).
- Softened NativeCard shadow + hairline border for light mode.
- Codemod: 113 dark-only `.white` foregrounds → `RTColor.primaryText` (kept 3 on accent fills).
- Verification: TEST SUCCEEDED — 58 tests, 0 failures; screenshot `.audit/bright-dashboard.png`.
- Branch: `feature/bright-apple-design`.

## 2026-09-04 — CI verification pipeline

- Added `.github/workflows/ci.yml` (macos-15, `xcodebuild test` on PRs + main).
- Added `scripts/ci-verify.sh` for Mac-mini / local parity with CI.
- Added `.cursor/skills/verify-readiness-tracker` agent verification skill + feature map.
- Next loops must pass `./scripts/ci-verify.sh` (and CI on PR) before merge.

## 2026-09-04 — Bright widget + Watch complication

- Home Screen widget: removed black canvas; `systemBackground` container; primary/secondary labels; Apple system score colors.
- Watch graphic-circular complication score uses `.primary` instead of hard white.
- Gate: `./scripts/ci-verify.sh` before merge (CI on PR).


## 2026-09-04 — Sleep disturbance wiring + light chart contrast

- `DayDetailView` now feeds `SleepCycleDetector.awakePeriods(from: data.sleepStages)` into `SleepDisturbanceTracker` (was hard-coded `[]`).
- Replaced chart/grid `.white.opacity(...)` styles with `RTColor.divider` / `RTColor.primaryText.opacity(...)` so baselines and axes read on bright cards.
- Gate: `./scripts/ci-verify.sh` + CI on PR.

## 2026-09-04 — Wire sleep timeline components

- `SleepAnalysisView`: real `HypnogramView(intervals:)`, `SleepCycleView` via `SleepCycleDetector.detectCycles`, `SleepDisturbanceTracker` via `awakePeriods`; toolbar `.light`.
- `DayDetailView`: compact non-interactive hypnogram above `SleepStageBreakdown`.
- `TrendDetailView` + `MetricDetailView`: `DepthTimelineChart` sections from filtered history / metric series.
- `WeeklyReportGenerator`: average sleep-cycle summary when stage data present; `WeeklyReportView` Cycles stat.
- `AIRecommendations` Rule 14: cycles < 4 and sleepHours > 5 → earlier bedtime / sleep quality.
- Branch: `feature/wire-sleep-timeline-components`.
- Gate: `DESTINATION='platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' ./scripts/ci-verify.sh`.


## 2026-09-05 — Lock Screen widgets + Fitbit config (no secrets in git)

- Added `AccessoryCircularWidgetView` / `AccessoryRectangularWidgetView` (system primary/secondary colors); extended `supportedFamilies` + `ReadinessWidgetView` switch (iOS 16+).
- `FitbitManager` reads `FITBIT_CLIENT_ID` / `FITBIT_CLIENT_SECRET` from Info.plist; rejects missing/placeholder and skips OAuth.
- `Secrets.xcconfig.example` + gitignore `Secrets.xcconfig`; Info.plist `$(FITBIT_*)` keys; `INFOPLIST_FILE` wired on app target.
- Docs: `docs/DEVICE_SETUP.md`; `FITBIT_SETUP.md` no longer instructs pasting secrets into Swift.
- Branch: `feature/lockscreen-fitbit-config`.
- Gate: `DESTINATION='platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' ./scripts/ci-verify.sh`.
