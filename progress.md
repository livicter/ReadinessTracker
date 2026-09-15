## 2026-09-16 — Poteto: Honest #47 Watch Check-in Morning|Evening

- Elevated Watch `WatchCheckInView` from morning-only stars+toggles to Morning|Evening picker (watchOS equivalent); keep feel stars + habit toggles (Evening adds Workout); `WatchSessionManager.sendCheckIn` sends correct `timeOfDay`.
- PNG: `.audit/verify-watch-checkin.png` via `Scripts/capture-watch-checkin.sh` (`WatchCheckInCaptureTests` + `ImageRenderer` of `WatchCheckInChrome`).
- Wired PNG through `capture-surfaces.sh` and `ci-guard-tree.sh`; README Status + App surfaces + Honest gap #47.
- Branch: `feature/poteto-watch-checkin-evening`.



## 2026-09-16 — Poteto: Honest #46 Watch complication accessoryCorner Fitness cues

- Elevated Watch `accessoryCorner` `widgetLabel` from plain monochrome `R… G… W… S…` text to colored readiness + short G/W/S cues (`WatchCornerComplicationView` + `WatchAccessoryCue`; rings from #44 kept; inline #45 cue parity).
- PNG: `.audit/verify-watch-complication-corner.png` via `Scripts/capture-watch-complication-corner.sh` (`WatchComplicationCaptureTests` + `ImageRenderer` of `WatchComplicationCornerChrome`).
- Wired PNG through `capture-surfaces.sh` and `ci-guard-tree.sh`; README Status + App surfaces + Honest gap #46.
- Branch: `feature/poteto-watch-complication-corner`.



## 2026-09-16 — Poteto: Honest #45 Watch complication accessoryInline Fitness cues

- Elevated Watch `accessoryInline` from plain monochrome `R… G… W… S…` text to colored readiness + short G/W/S (R/G/W/S) cues within inline width (`WatchInlineComplicationView`; Lock #34 / rect #44 parity).
- PNG: `.audit/verify-watch-complication-inline.png` via `Scripts/capture-watch-complication-inline.sh` (`WatchComplicationCaptureTests` + `ImageRenderer` of `WatchComplicationInlineChrome`).
- Wired PNG through `capture-surfaces.sh` and `ci-guard-tree.sh`; README Status + App surfaces + Honest gap #45.
- Branch: `feature/poteto-watch-complication-inline`.



## 2026-09-16 — Poteto: Honest #44 Watch complication rectangular Fitness parity

- Elevated Watch `accessoryRectangular` from thin Ready/G-W-S text beside fixed rings to Lock Screen (#33) parity: GeometryReader-scaled `CompactTripleRingsView` + Readiness score + colored G/W/S cues; corner uses compact rings + readiness/G/W/S label.
- PNG: `.audit/verify-watch-complication-rectangular.png` via `Scripts/capture-watch-complication-rectangular.sh` (`WatchComplicationCaptureTests` + `ImageRenderer` of `WatchComplicationRectangularChrome`).
- Wired PNG through `capture-surfaces.sh` and `ci-guard-tree.sh`; README Status + App surfaces + Honest gap #44.
- Branch: `feature/poteto-watch-complication-rectangular`.



## 2026-09-16 — Poteto: Honest #43 widget export on all write paths

- Audited `WidgetDataExporter.export` call sites: HealthKit/Fitbit already hit export via `DataStore.persist`; Morning/Evening Check-in (`MetadataStore.save` from `CheckInView` + Watch Connectivity check-in) did **not**.
- Added shared `WidgetExportAfterWrite.run()` (export + watch pushSnapshot; testable `testPerform` hook). Wired `DataStore.persist` + `MetadataStore.persist`. No extra WidgetCenter.reload outside exporter.
- Unit: `WidgetExportAfterWriteTests`; proof `.audit/h43-unit-test-proof.txt` (UI unchanged). README Honest gap #43.
- Branch: `feature/poteto-widget-export-all-paths`.

## 2026-09-16 — Poteto: Honest #42 Home widget live Updated + App Group snapshot

- Prefer WidgetKit live relative time: `Text(lastUpdate, style: .relative)` (prefix “Updated ”) via `WidgetUpdatedCue` / `HomeWidgetLiveUpdatedCue` instead of baked `RelativeDateTimeFormatter` string; keep `Date?` on entry.
- `getSnapshot` loads App Group via shared `HomeWidgetAppGroupEntry` (same as `getTimeline`), falling back to sample only when suite empty.
- PNG: `.audit/verify-home-widget-live-updated.png` via `Scripts/capture-home-widget-live-updated.sh` (`HomeWidgetCaptureTests` + ImageRenderer).
- Unit: `HomeWidgetAppGroupEntryTests`; wired PNG through `capture-surfaces.sh` and `ci-guard-tree.sh`; README Status + App surfaces + Honest gap #42.
- Branch: `feature/poteto-home-widget-live-updated`.




## 2026-09-16 — Poteto: Honest #41 Home widget Updated freshness

- Thread App Group `lastUpdate` into `ReadinessEntry` from Provider; Fitness-style **Updated …** cue on `MediumWidgetView` / `LargeWidgetView` / `ExtraLargeWidgetView` (graceful if missing; accessories uncluttered).
- PNG: `.audit/verify-home-widget-updated.png` via `Scripts/capture-home-widget-updated.sh` (`HomeWidgetCaptureTests` + `ImageRenderer` of `HomeWidgetUpdatedChrome` medium chrome).
- Wired PNG through `capture-surfaces.sh` and `ci-guard-tree.sh`; README Status + App surfaces + Honest gap #41.
- Branch: `feature/poteto-home-widget-updated`.




## 2026-09-16 — Poteto: Honest #40 Home widget Extra Large

- Added Home Screen `.systemExtraLarge` (`ExtraLargeWidgetView`): Fitness-style `CompactTripleRingsView` (larger) + readiness High/Moderate/Low cue + Gym/Work/Sleep score rows + HRV/RHR/Sleep hours + G/W/S metric tiles; Check-in / Evening / Trends deep links (parity with large). Wired `supportedFamilies` + `ReadinessWidgetView` switch.
- PNG: `.audit/verify-home-widget-extra-large.png` via `Scripts/capture-home-widget-extra-large.sh` (`HomeWidgetCaptureTests` + `ImageRenderer` of `HomeWidgetExtraLargeChrome`).
- Wired PNG through `capture-surfaces.sh` and `ci-guard-tree.sh`; README Status + App surfaces + Honest gap #40.
- Branch: `feature/poteto-home-widget-extra-large`.





## 2026-09-16 — Poteto: Honest #39 complication transfer throttle

- Throttle scarce WC `transferCurrentComplicationUserInfo` (~50/day): only spend a complication-priority transfer when glance-relevant fields change (readiness/gym/work/sleep + recovery/strain fingerprint). Unchanged scores still write App Group + fall back to `updateApplicationContext` / reachable message.
- Persist last-sent glance fingerprint in UserDefaults (`WatchComplicationWCPush.FingerprintStore`); seam injectable for tests.
- Proof: focused XCTest `WatchComplicationWCPushTests` (changed→transfer vs unchanged→skip transfer + context). UI unchanged — reuse `.audit/verify-watch-complication.png`. Portal App Group enable remains manual in `docs/DEVICE_SETUP.md`.
- README Status + App surfaces + Honest gap #39.
- Branch: `feature/poteto-watch-complication-transfer-throttle`.






# Progress

## 2026-09-16 — Poteto: Honest #38 WatchConnectivity complication push

- When iOS pushes/updates `WatchSnapshot`, prefer WC `transferCurrentComplicationUserInfo` while `remainingComplicationUserInfoTransfers > 0`; else fall back to existing `updateApplicationContext` / reachable message (`WatchComplicationWCPush` seam). Soft-fail if session inactive / budget exhausted.
- Watch `WatchSessionManager` handles `didReceiveUserInfo` (complication transfers) with the same App Group persist + `WatchComplicationTimelineReloader` path as context/message.
- Proof: focused XCTest `WatchComplicationWCPushTests` (route preference + deliver seams + soft-fail context throw). UI unchanged — reuse `.audit/verify-watch-complication.png`. Portal App Group enable remains manual in `docs/DEVICE_SETUP.md`.
- Wired helper into iOS target + tests into `ReadinessTracker.xcodeproj`; README Status + App surfaces + Honest gap #38.
- Branch: `feature/poteto-watch-complication-wc-push`.






## 2026-09-16 — Poteto: Honest #37 Watch complication WidgetKit timeline reload

- After successful Watch App Group mirror write (`WatchSessionManager.persistSnapshotDictionary`), soft-fail reload Watch Widgets timelines via `WatchComplicationTimelineReloader` → `WidgetCenter.shared.reloadTimelines(ofKind: "ReadinessWatchComplication")` so complications update without waiting for the next timeline policy.
- Proof: focused XCTest `WatchComplicationTimelineReloaderTests` (kind match + injected reload seam + default soft-fail). UI unchanged — reuse `.audit/verify-watch-complication.png`. Portal App Group enable remains manual in `docs/DEVICE_SETUP.md`.
- Wired reloader into iOS + Watch App targets; test into `ReadinessTracker.xcodeproj`; README Status + App surfaces + Honest gap #37.
- Branch: `feature/poteto-watch-complication-reload`.






## 2026-09-16 — Poteto: Honest #36 iOS App Group `lastWatchSnapshot` writer

- Closed data-path hole: iOS now writes App Group `group.com.readinesstracker` / `lastWatchSnapshot` when pushing/updating Watch snapshots via `WatchSnapshotAppGroupStore` from `WatchConnectivityManager.pushSnapshot()` (always, even if WC inactive) and `WidgetDataExporter.export(...)`. Watch `WatchSessionManager` mirror unchanged for the watch-side container.
- Proof: focused XCTest `WatchSnapshotAppGroupStoreTests` (encode/write/read round-trip). UI unchanged — reuse `.audit/verify-watch-complication.png`. Portal App Group enable remains manual in `docs/DEVICE_SETUP.md` (Status note).
- Wired test into `ReadinessTracker.xcodeproj`; README Status + App surfaces + Honest gap #36.
- Branch: `feature/poteto-watch-complication-appgroup`.





## 2026-09-16 — Poteto: Watch complication Fitness-style triple rings

- Shipped WidgetKit Watch Widgets extension (`ReadinessTrackerWatchWidgets`) embedded in `ReadinessTrackerWatch Watch App`: `accessoryCircular` (+ rectangular / inline / corner) Fitness-style `CompactTripleRingsView` via shared `TripleRingGeometry`. Timeline reads App Group `lastWatchSnapshot` (sample fallback). Removed dead orphan `ReadinessTrackerWatch/Complications/ReadinessComplication.swift`.
- PNG: `.audit/verify-watch-complication.png` via `Scripts/capture-watch-complication.sh` (`WatchComplicationCaptureTests` + `ImageRenderer` of `WatchComplicationChrome`). Geometry unit test covers complication score-font band.
- Wired PNG through `capture-surfaces.sh` and `ci-guard-tree.sh`; README Status + App surfaces + Honest gap #35; corrected Elsewhere “shipped complications” claim to match.
- Branch: `feature/poteto-watch-complication-rings`.





## 2026-09-16 — Poteto: Lock Screen accessoryInline compact text glance

- Added Lock Screen `.accessoryInline` (`AccessoryInlineWidgetView`): readiness score + short G/W/S cues as a single-line text glance beside Lock Screen time. Wired `supportedFamilies` + `ReadinessWidgetView` switch (iOS 16+). Circular/rectangular evidence unchanged.
- PNG: `.audit/verify-lock-widget-inline.png` via `Scripts/capture-lock-widget-inline.sh` (`LockWidgetCaptureTests` + `ImageRenderer` of `LockScreenInlineChrome`).
- Wired PNG through `capture-surfaces.sh` and `ci-guard-tree.sh`; README Status + App surfaces + Honest gap #34.
- Branch: `feature/poteto-lock-inline`.





## 2026-09-16 — Poteto: Apple Fitness Lock Screen accessory rectangular triple-ring parity

- Elevated Lock Screen `AccessoryRectangularWidgetView` from readiness digit + Gym/Work/Sleep score rows to Fitness-style `CompactTripleRingsView` + readiness score + short G/W/S cues (GeometryReader-scaled for accessory height; caption off). Circular evidence unchanged.
- PNG: `.audit/verify-lock-widget-rectangular.png` via `Scripts/capture-lock-widget-rectangular.sh` (`LockWidgetCaptureTests` + `ImageRenderer` of `LockScreenRectangularChrome`). Geometry unit test covers rectangular accessory score-font band.
- Wired PNG through `capture-surfaces.sh` and `ci-guard-tree.sh`; README Status + App surfaces + Honest gap #33.
- Branch: `feature/poteto-lock-rectangular-triple-rings`.




## 2026-09-14 — Poteto evening: more App deep links (Evening Check-in + Trends)

- Extended `AppDeepLink` with `checkInEveningURL` (`readinesstracker://checkin/evening`) + `trends` (`readinesstracker://trends` → History browse). Fitbit `oauth` unchanged.
- Medium widget secondary **Trends** `Link`; large shows Check-in / Evening / Trends. ContentView + AppDelegate route tab selection.
- PNG: `.audit/verify-home-widget-deeplinks.png` via `Scripts/capture-home-widget-deeplinks.sh` (`HomeWidgetCheckInCaptureTests` + `ImageRenderer` of `HomeWidgetCheckInChrome`).
- Wired PNG through `capture-surfaces.sh` and `ci-guard-tree.sh`; README Status + App surfaces + Honest gap #32.
- Branch: `feature/poteto-evening-deeplinks`.



## 2026-09-14 — Poteto: Home widget interactive Check-in control

- Elevated Home Screen widgets: medium/large show Fitness-style **Check-in** `Link`; all families use `.widgetURL` → `readinesstracker://checkin/morning`. App routes via `AppDeepLink` + ContentView tab / Morning (Fitbit `oauth` host unchanged).
- PNG: `.audit/verify-home-widget-checkin.png` via `Scripts/capture-home-widget-checkin.sh` (`HomeWidgetCheckInCaptureTests` + `ImageRenderer` of `HomeWidgetCheckInChrome`). Large chrome also shows Check-in.
- Wired PNG through `capture-surfaces.sh` and `ci-guard-tree.sh`; README Status + App surfaces + Honest gap #31.
- Branch: `feature/poteto-home-widget-checkin`.


## 2026-09-14 — Poteto: WHOOP Watch Strain/Recovery dual-arc parity

- Elevated Watch `WatchStrainView` from single `ScoreRing` to WHOOP dual concentric arcs (Recovery inner / Strain outer) via shared `StrainRecoveryDualArcGeometry` + `CompactStrainRecoveryWheel` (Watch App Sources; no UIKit). Today `StrainRecoveryWheel` now uses the same geometry helper.
- PNG: `.audit/verify-watch-strain.png` via `Scripts/capture-watch-strain.sh` (`WatchStrainCaptureTests` + `ImageRenderer` of `WatchStrainChrome`). Watch scheme build verified when simulator available.
- Wired PNG through `capture-surfaces.sh` and `ci-guard-tree.sh`; README Status + App surfaces + Honest gap #30.
- Branch: `feature/poteto-watch-strain-dual-arcs`.





## 2026-09-14 — Poteto: Apple Fitness / Google Health large Home widget parity

- Elevated Home Screen widget: added `.systemLarge` (`LargeWidgetView`) with Fitness-style `CompactTripleRingsView` + Gym/Work/Sleep `ScoreRow`s + HRV/RHR/Sleep `MetricMini`s (reuse Medium patterns). Wired `supportedFamilies` + `ReadinessWidgetView` switch. Watch complication untouched.
- PNG: `.audit/verify-home-widget-large.png` via `Scripts/capture-home-widget-large.sh` (`HomeWidgetCaptureTests` + `ImageRenderer` of `HomeWidgetLargeChrome`).
- Wired PNG through `capture-surfaces.sh` and `ci-guard-tree.sh`; README Status + App surfaces + Honest gap #29.
- Branch: `feature/poteto-home-widget-large`.




## 2026-09-10 — Poteto: Apple Fitness Lock Screen accessory circular triple-ring parity

- Elevated Lock Screen `AccessoryCircularWidgetView` from single `.accessoryCircularCapacity` gauge to Fitness-style concentric Gym/Work/Sleep via shared `CompactTripleRingsView` + `TripleRingGeometry` (GeometryReader-scaled; caption off). Rectangular accessory kept with minor Gym/Work/Sleep digit color align.
- PNG: `.audit/verify-lock-widget.png` via `Scripts/capture-lock-widget.sh` (`LockWidgetCaptureTests` + `ImageRenderer` of `LockScreenAccessoryChrome`). Geometry unit test covers accessory score-font floor.
- Wired PNG through `capture-surfaces.sh` and `ci-guard-tree.sh`; README Status + App surfaces + Honest gap #28.
- Branch: `feature/poteto-lock-widget-triple-rings`.



## 2026-09-09 — Poteto: Apple Fitness Watch dashboard triple-ring glance parity

- Elevated Watch `WatchDashboardView` hero from single `ScoreRing` to Fitness-style concentric Gym/Work/Sleep via shared `CompactTripleRingsView` + `TripleRingGeometry` (added to Watch App Sources; UIKit chrome gated with `os(iOS)`).
- `WatchSnapshot` + iPhone `WatchConnectivityManager` push `gymScore` / `workScore` / `sleepScore` (same dual-score path as `WidgetDataExporter`).
- PNG: `.audit/verify-watch-dashboard.png` via `Scripts/capture-watch-dashboard.sh` (`WatchDashboardCaptureTests` + `ImageRenderer` of `WatchDashboardChrome`). Watch scheme build verified when simulator available.
- Wired PNG through `capture-surfaces.sh` and `ci-guard-tree.sh`; README Status + App surfaces + Honest gap #27.
- Branch: `feature/poteto-watch-dashboard-triple-rings`.


## 2026-09-09 — Poteto: Apple Fitness home-widget triple-ring parity

- Elevated Home Screen widget: `SmallWidgetView` + medium left score use Fitness-style concentric Gym/Work/Sleep rings (scores already on `ReadinessEntry`); medium metric rows keep Gym/Work/Sleep bars with matching ring colors.
- Shared `TripleRingGeometry` + snapshot-safe `CompactTripleRingsView` / `HomeWidgetSmallChrome` (app + widget targets); Today `TripleRingHero` now uses the same geometry helper.
- Unit tests: `TripleRingGeometryTests`. PNG: `.audit/verify-home-widget.png` via `Scripts/capture-home-widget.sh` (`HomeWidgetCaptureTests` + `ImageRenderer`; WidgetKit UITest not required).
- Wired PNG through `capture-surfaces.sh` and `ci-guard-tree.sh`; README Status + Honest gap #26.
- Branch: `feature/poteto-home-widget-triple-rings`.

## 2026-09-09 — Poteto: WHOOP Strain/Recovery dual-arc wheel parity (Option A)

- Elevated `StrainRecoveryWheel`: concentric dual arcs (outer Strain 0–21, inner Recovery 0–100%), center Recovery %, Recovery | Strain value legend (not sequential single-ring).
- `RecoveryStrainDetailView` now reuses `StrainRecoveryWheel` (was duplicated inline dual rings).
- `SurfaceID.strainRecoveryWheel` / `…Legend` / `…Recovery` / `…Strain` (`strain.recovery.wheel[.legend|.recovery|.strain]`).
- UITest: `testStrainRecoveryWheelSurface` soft-checks dual-arc chrome → `verify-strain-wheel.png`.
- Wired PNG through `capture-surfaces.sh` and `ci-guard-tree.sh`; README Status + App surfaces + Honest gap #25.
- Branch: `feature/poteto-strain-recovery-wheel`.


## 2026-09-09 — Poteto: WHOOP Sleep Debt presentation parity (Option A)

- Elevated `SleepDebtCalculator`: Debt | Last night dual hours, zero-centered debt/surplus gauge, payback cue (≈hours over N nights at +1.0h), 7-night balance `AnimatedSparkline`, daily vs need zero-centered bars.
- `SurfaceID.sleepDebtHours` / `sleepDebtPayback` / `sleepDebtSpark` / `sleepDebtBars` (`sleep.debt.hours|payback|spark|bars`).
- UITest: `testSleepDebtSurfaceVisibleAfterScroll` soft-checks elevated chrome → `verify-sleep-debt.png`.
- Wired PNG through `capture-surfaces.sh` and `ci-guard-tree.sh` (existing name); README Status + App surfaces + Honest gap #24.
- Branch: `feature/poteto-sleep-debt-whoop`.







## 2026-09-09 — Poteto: WHOOP/GH Day Detail / Sleep Analysis night-detail parity (Option A)

- Elevated `DayDetailView` sleep section toward WHOOP night-detail: sleep score + **Asleep | In Bed | Efficiency** header, stage % chips (Deep/REM/Light/Awake), Sleep Timeline hypnogram, cycles summary; Full Sleep Analysis link retained.
- Elevated `SleepAnalysisView` entry with Stage Mix % chips; hypnogram a11y id shared for capture.
- `SurfaceID.dayDetail` / `dayDetailHeader` / `dayDetailStageChips` / `dayDetailHypnogram` / `dayDetailCycles`.
- UITest: `testDayDetailSurface` (History → day row, fallback Today → Sleep Stages) → `verify-day-detail.png`.
- Wired PNG through `capture-surfaces.sh` and `ci-guard-tree.sh`; README Status + App surfaces + Honest gap #23.
- Branch: `feature/poteto-day-detail-whoop`.






## 2026-09-09 — Poteto: History Trends / TrendDetail Health Browse parity (Option A)

- Elevated `TrendDetailView` toward Apple Health / Google Health Browse: clearer period chips (7D/30D/90D/1Y), summary **Avg / Min / Max / Change %** row for primary metric, drag scrub (`ChartScrubSelection`) on multi-metric chart.
- History tab Trends section → `NavigationLink` **Browse Trends** into `TrendDetailView` (preview chart retained).
- `SurfaceID.trendsDetail` / `trendsSummary` / `trendsChartScrub` / `trendsChartSelection` / `historyTrendsLink`.
- UITest: `testTrendsDetailSurface` → `verify-trends.png`.
- Wired PNG through `capture-surfaces.sh` and `ci-guard-tree.sh`; README Status + App surfaces + Honest gap #22.
- Branch: `feature/poteto-trends-health-browse`.






## 2026-09-09 — Poteto: WHOOP Sleep Consistency / Quality presentation parity (Option A)

- Elevated `SleepConsistencyTracker`: clearer overall score ring, Bedtime | Wake dual %, 7-night bedtime-vs-average dots/bars, compact consistency `AnimatedSparkline`, bedtime trend chart retained.
- Elevated `SleepQualityTrend`: clearer avg score ring, compact 7-day quality sparkline, score bars + daily mini rings retained.
- `SurfaceID.sleepConsistency*` / `sleepQuality*` (`sleep.consistency.score|dual|bedtime|spark`, `sleep.quality.score|spark`).
- UIFixture varies older-night bed/wake + sleepHours so dots/bars/sparks show shape; today stays 23:05 / 07:10 / 7.4h.
- UITest: `testSleepQualitySurfaceVisibleAfterScroll` soft-checks elevated chrome → `verify-sleep-quality.png`.
- Wired through `capture-surfaces.sh` and `ci-guard-tree.sh`; README Status + App surfaces + Honest gap #21.
- Branch: `feature/poteto-sleep-consistency-quality-whoop`.






## 2026-09-09 — Poteto: WHOOP Respiratory Rate + Skin Temperature card parity (Option A)

- Elevated `RespiratoryRateCard` + `SkinTemperatureCard`: Tonight | Baseline dual metric, delta badge, baseline band on trend chart, compact 7-night `AnimatedSparkline`.
- Full-width stack on Today (and Recovery & Strain detail) instead of cramped side-by-side half cards.
- `SurfaceID.respiratory*` / `skinTemp*` (`respiratory.card|baseline|spark`, `skin.temp.card|baseline|spark`); `RTColor.respiratory` / `skinTemp`.
- UIFixture varies older-night RR / skin temp so spark/chart show shape; today stays 15.2 bpm / 36.40°C.
- UITest: `testRespiratoryRateSurface` → `verify-respiratory.png`; `testSkinTemperatureSurface` → `verify-skin-temp.png`.
- Wired PNGs through `capture-surfaces.sh` and `ci-guard-tree.sh`; README Status + App surfaces + Honest gap #20.
- Branch: `feature/poteto-resp-skin-whoop`.






## 2026-09-08 — Poteto: WHOOP Sleep HRV card/graphics parity (Option A)

- Elevated `SleepHRVCard`: Tonight | Baseline dual metric (ms RMSSD), % delta badge, ±10% baseline band on trend chart, compact 7-night `AnimatedSparkline`, Sleep Quality one-liner.
- `SurfaceID.sleepHRVBaselineCallout` / `sleepHRVSpark` (`sleep.hrv.baseline` / `sleep.hrv.spark`).
- UIFixture varies older-night HRV so spark/chart show shape; today stays 58 ms.
- UITest: `testSleepHRVSurface` → `verify-sleep-hrv.png`.
- Wired PNG through `capture-surfaces.sh` and `ci-guard-tree.sh`; README Status + App surfaces + Honest gap #19.
- Branch: `feature/poteto-sleep-hrv-whoop`.






## 2026-09-08 — Poteto: Body & activity Google Health / Fitness tiles (Option A)

- Elevated Body tiles: progress-to-goal rings (Steps 10k / Activity 30 min / Calories 500 / Water / Protein), 7-day sparklines, chevron.
- Tap tile → `BodyMetricDetailView` sheet (value, goal ring, Last 7 days spark + bars). Label stays **Activity** (not Heart Points).
- `BodyMetricKind` + `BodyMetricTile` in `Components.swift`; `SurfaceID.bodyDetail` / `body.tile.*`.
- UIFixture varies older-day steps/Activity/calories so sparklines are real; today stays 8200 / 42 / 420.
- UITest: `testBodyActivityVisibleAfterScroll` strengthened; `testBodyDetailSurface` → `verify-body-detail.png`.
- Wired PNG through `capture-surfaces.sh` and `ci-guard-tree.sh`; README Status + App surfaces + Honest gap #18.
- Branch: `feature/poteto-body-metric-detail`.





## 2026-09-08 — Poteto: WHOOP Sleep Performance Need vs Got (Option A)

- Elevated `SleepPerformanceScore`: side-by-side **Need | Got** dual metric (14-night average vs last night), clearer comparative bar with need marker, performance % ring retained.
- Efficiency / Consistency stay compact one-liners (unchanged role).
- `SurfaceID.sleepPerformance` (`sleep.performance`) + `sleep.performance.needGot`.
- UITest: `testSleepPerformanceSurface` → `verify-sleep-performance.png`.
- Wired PNG through `capture-surfaces.sh` and `ci-guard-tree.sh`; README Status + App surfaces + Honest gap #17.
- Branch: `feature/poteto-sleep-performance-need-got`.






## 2026-09-08 — Poteto: WHOOP-style Recommendations / Coaching cards (Option A)

- Today Recommendations: `RecommendationActionCard` (title, reason, action cue) via `AIRecommendationEngine.morningActionableCards` — training rules first, coaching insights fill to 1–3 (no placeholder / lying UI).
- `TrainingRecommendation.action` with sensible defaults; Coaching feed a11y ids.
- UITest: `testRecommendationsSurface` → `verify-recommendations.png`; `testCoachingSurface` → `verify-coaching.png` (Settings → Coaching).
- Unit: `testUIFixtureMorningActionableCardsNonEmpty`, `testTrainingRecommendationDefaultAction`.
- Wired PNGs through `capture-surfaces.sh` and `ci-guard-tree.sh`; README Status + App surfaces + Honest gap #16.
- Branch: `feature/poteto-whoop-coaching-recs`.





## 2026-09-08 — Poteto: WHOOP-parity Strain/Recovery on Today (Option C)

- Elevated `StrainRecoveryBalanceCard`: side-by-side Recovery % | Strain /21 with day-over-day deltas, balance score + status, chevron.
- Today balance card is tappable → `RecoveryStrainDetailView` (wheel header already was).
- Compact 7-day recovery sparkline (`AnimatedSparkline`) under the Strain/Recovery wheel.
- UITest: `testStrainRecoveryBalanceSurface` → `verify-strain-recovery.png`.
- Wired PNG through `capture-surfaces.sh` and `ci-guard-tree.sh`; README Status + App surfaces + Honest gap #15.
- Branch: `feature/poteto-strain-recovery-today`.






## 2026-09-08 — Poteto: Journal Behavior Impact under UIFixture (Option D)

- Seed ≥8 `JournalEntry` rows in `UIFixture.installIfRequested` → `UserDefaults` `journal_entries` (same key as `JournalView`), with varied habits + readiness scores so Behavior Impact is non-empty under `-ui-fixture`.
- Real users with <7 days still see the “Log 7 days…” empty strip (gate unchanged).
- UITest: `testJournalSurface` asserts Recent Entries; `testJournalImpactSurface` → `verify-journal-impact.png`.
- Unit: `testUIFixtureJournalEntriesSeedImpactThreshold` in `SleepStageIntervalTests`.
- Wired PNG through `capture-surfaces.sh` and `ci-guard-tree.sh`; README Status + App surfaces + Honest gap #14.
- Branch: `feature/poteto-journal-impact-fixture`.





## 2026-09-08 — Poteto: Apple Fitness–style ring detail (Option B)

- Legend taps on Gym / Work / Sleep open `RingDetailView` sheet: score, matching color/label, 7-day sparkline + mini bars from `UIFixture` / `DailyHealthData` (Gym→`workoutMinutes`, Work→`hrv`, Sleep→`sleepHours`).
- `RingKind` + detail live in `TripleRingView.swift`; Dashboard hero keeps NavigationLink on rings, legend outside for taps.
- UITest: `testRingDetailSurface` → `verify-ring-detail.png`; wired through `capture-surfaces.sh` and `ci-guard-tree.sh`; README Status + App surfaces + Honest gap #13.
- Branch: `feature/poteto-ring-detail`.






## 2026-09-08 — Poteto: MetricDetailView ChartScrubSelection scrub + tooltip

- Applied Apple Health–style drag scrub to `MetricDetailView` primary Trend chart: `ChartScrubSelection` nearest-date map, RuleMark, `ChartTooltip` callout; clears on lift; Reduce Motion skips scrub haptics (parity with `AdvancedMetricChartView`).
- Today → Metrics cards open `MetricDetailView` (classic detail + Depth Timeline). Score breakdown bars still open `AdvancedMetricDetailView`.
- UITest: `testMetricDetailChartScrubSurface` → classic PNG; `testAdvancedMetricDetailChartScrubSurface` via Breakdown `breakdown.Sleep` → Advanced scrub PNG.
- Wired classic PNG through `capture-surfaces.sh` and `ci-guard-tree.sh`; README Status + App surfaces + Honest gap #12.
- Branch: `feature/poteto-metric-detail-scrub`.






## 2026-09-08 — Poteto: Apple Health–style chart scrub / value callout

- Upgraded `AdvancedMetricChartView` (Today → metric detail) from tap-only to drag scrub with RuleMark + `ChartTooltip` callout; clears on lift (Health-like).
- Extracted `ChartScrubSelection` helper (nearest date + fraction map + callout text); `DepthTimelineChart` shares it. Reduce Motion skips scrub haptics.
- Unit: `ChartScrubSelectionTests`. UITest: `testMetricDetailChartScrubSurface` opens Sleep detail under `-ui-fixture`, asserts period selector + chart, saves `verify-metric-detail-scrub.png`.
- Wired PNG through `capture-surfaces.sh` and `ci-guard-tree.sh`; README Status + App surfaces + Honest gap #11.
- Branch: `feature/poteto-chart-scrub-callout`.





## 2026-09-08 — Poteto: coherent UIFixture sleepStages (hypnogram honesty)

- Fixed `HypnogramView` Y bands: stages used positive `depthRank` while `chartYScale` was `-4...0`, so only Awake rendered; now use `hypnogramYStart/End` (negated ranks).
- Seeded `UIFixture.coherentSleepStages` (one mid-sleep awake) and derive `wakeEpisodes` from `SleepCycleDetector.awakePeriods` so Today disturbance count matches Sleep Analysis / Day Detail hypnogram.
- Unit: `testUIFixtureCoherentSleepStagesMatchWakeEpisodes` in `SleepStageIntervalTests`.
- UITest: `testSleepStagesSurface` opens Today → Sleep Stages → Sleep Analysis and saves `verify-sleep-stages.png`.
- Wired PNG through `capture-surfaces.sh` and `ci-guard-tree.sh`; README Status + App surfaces + Honest gap #10.
- Branch: `feature/poteto-coherent-sleep-stages-fixture`.





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
