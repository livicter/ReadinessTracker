# ReadinessTracker

iOS readiness app. Bright Apple Health UI. Local HealthKit plus optional Fitbit. WHOOP product surfaces via Apple Health. No unofficial WHOOP OAuth.

**main:** Gym / Work / Sleep rings use Apple Activity packing with a center READY score in a Fitness-scale hole. Today scroll keeps Morning and Evening above the tab bar. Body sits above the WHOOP stack.

Screenshots are Simulator captures from `./scripts/capture-surfaces.sh` (XCUITest swipe plus `-ui-fixture`, not VoiceOver).

## Status

| Surface | Status | Evidence |
|---|---|---|
| Today hero, Gym / Work / Sleep rings | Shipped. Concentric Activity geometry (`size/10` stroke, gap 2), packed center READY score, one `-90` start, round caps, no tip dots, no hairline halo | [verify-rings.png](.audit/verify-rings.png) |
| Source chips + **WHOOP via Apple Health** | Shipped | [verify-dashboard.png](.audit/verify-dashboard.png) |
| Morning / Evening check-in cards | Shipped. First screen ends at the sync bar. Scrolled Today shows both cards above the tab bar. Morning/Evening stay on one line on the half-card | dashboard + body frames |
| Check-in tab (Morning / Evening form) | Shipped. Dedicated capture opens the Check-in tab (segmented picker + Save) | [verify-checkin.png](.audit/verify-checkin.png) |
| History tab (Weekly Report + Trends) | Shipped. Dedicated capture opens the History tab (source picker, Weekly Report, Trends) | [verify-history.png](.audit/verify-history.png) |
| Recovery / Strain wheel | Shipped | [verify-whoop-stack.png](.audit/verify-whoop-stack.png) |
| Sleep Performance (14-night need) | Shipped. Efficiency and Consistency are one line | whoop frame |
| Sleep HRV (RMSSD) | Shipped. Header and 58 ms in the whoop frame. Trend / Sleep Quality chips sit below the chart | whoop + sleep-quality frames |
| Sleep Debt | Shipped. Dedicated capture scrolls Today to the Sleep Debt card | [verify-sleep-debt.png](.audit/verify-sleep-debt.png) |
| Sleep Quality / Consistency cards | Shipped. Fifth capture scrolls to Sleep Quality Trend + Sleep Consistency | [verify-sleep-quality.png](.audit/verify-sleep-quality.png) |
| Body & activity (steps, Activity min, calories, SpO2, water, caffeine, protein) | Shipped, **above** the WHOOP stack. Label is Activity, not Heart Points | [verify-body-activity.png](.audit/verify-body-activity.png) |
| Sleep disturbance count on Today sleep row | Shipped | `DashboardView` sleep card |
| Journal “log 7 days” strip | Shipped. Dedicated capture opens Journal from Today (empty-state Log 7 days strip) | [verify-journal.png](.audit/verify-journal.png) |
| Settings connect / reconnect + cycle toggle off | Shipped | [verify-settings-sources.png](.audit/verify-settings-sources.png) |
| Official WHOOP API | Out of scope | Settings copy says so |
| Google Fit REST / “Heart Points” | Out of scope | Activity = minutes + calories |

## Supported features

Four tabs stay Today, History, Check-in, and Settings.

**Data.** Apple Health (HealthKit) is the default source. Fitbit is optional OAuth via gitignored `Secrets.xcconfig`. WHOOP values appear when the user shares WHOOP into Apple Health. `DataSource` is appleWatch or fitbit only.

**Today.** Readiness hero with Gym / Work / Sleep rings (`TripleRingHero`). Morning and Evening check-in. Journal. Recommendations. Body and activity (steps, Activity minutes, calories, SpO2, water, caffeine, protein). WHOOP stack (Recovery, Strain, Sleep Performance, Sleep HRV, Sleep Debt, Sleep Quality, Sleep Consistency). Sleep stages with disturbance count. Trends and score breakdown.

**Scores.** Recovery 0-100 from `RecoveryCalculator`. Strain TRIMP 0-21. Sleep need is the 14-night average from `BaselineManager`. HRV is RMSSD. Wheel recovery uses `RecoveryCalculator.dashboardWheelScore`.

**Check-in and journal.** Morning and Evening cards open Check-in for that time. Journal impact chart waits for 7 days of entries.

**Settings.** Apple Health Connect / Reconnect. Fitbit Connect / Refresh / Disconnect. Cycle tracking off by default. CSV export. Coaching and notification screens.

**Elsewhere.** History with weekly report. Home screen widgets and Watch complications (bright Apple Health tokens). Lock Screen widgets.

**Not in this app.** Unofficial WHOOP login. Google Fit REST. Heart Points.

## App surfaces

### Today

Bright grouped background. Dark selected Apple Watch chip. WHOOP-via-Health caption. Readiness 90 / Ready to perform. Rings match Activity packing. Sync bar sits above the tab bar.

![Today dashboard](.audit/verify-dashboard.png)

### Triple rings

Same first screen, captured for ring geometry. Concentric Activity diameters; center READY typography packs into a Fitness-Summary-scale hole (no longer an oversized empty core).

![Today rings](.audit/verify-rings.png)

### Recovery, sleep performance, HRV

Scrolled Today after Body. Need caption is the 14-night average. Efficiency and Consistency do not wrap mid-word.

![WHOOP stack](.audit/verify-whoop-stack.png)

### Sleep debt

Scrolled Today to the Sleep Debt card (cumulative vs need). Sits after Sleep HRV and before Sleep Quality Trend.

![Sleep debt](.audit/verify-sleep-debt.png)

### Sleep quality and consistency

Scrolled further on Today past Sleep Debt. Sleep Quality Trend and Sleep Consistency cards (Sleep HRV chips when still in frame).

![Sleep quality](.audit/verify-sleep-quality.png)

### Body and activity

Sits above Recovery and Strain. Label is **Activity**, not Heart Points. Morning and Evening are fully above the tab bar in this frame. Morning and Evening labels stay on one line.

![Body and activity](.audit/verify-body-activity.png)

### Settings, data sources

Apple Health connected plus Reconnect. Fitbit Connect with missing-secrets error (expected without `Secrets.xcconfig`). Cycle tracking off.

![Settings data sources](.audit/verify-settings-sources.png)

### Check-in tab

Dedicated Check-in tab (not the Today Morning/Evening cards). Segmented Morning/Evening picker, Physical State form, and Save under `-ui-fixture`.

![Check-in tab](.audit/verify-checkin.png)

### History tab

Dedicated History tab. Segmented Apple Watch / Fitbit source picker, Weekly Report row, Trends section, and day list under `-ui-fixture` (14 seeded Apple Watch days).

![History tab](.audit/verify-history.png)

### Journal

Opened from Today’s Journal row. Empty-state copy plus the “Log 7 days to see how habits line up with next-day readiness.” strip under `-ui-fixture`.

![Journal](.audit/verify-journal.png)

## Verify

Push and pull request to `main` run three required GitHub Actions jobs.

1. Tree guard (`./scripts/ci-guard-tree.sh`). Fails if git tracks `build/`, `Readiness.app`, `Secrets.xcconfig`, `xcuserdata`, or `Heart Points` in Swift. Also fails if a committed `.audit/verify-*.png` is missing.
2. iOS unit tests (`./scripts/ci-verify.sh`). `ReadinessTrackerTests` only.
3. iOS UI surfaces (`./scripts/capture-surfaces.sh`). Ten XCUITests with `-ui-fixture`. PNGs upload as the `ui-surfaces` artifact.

```bash
./scripts/ci-guard-tree.sh

DESTINATION='platform=iOS Simulator,name=iPhone 17 Pro' ./scripts/ci-verify.sh

DESTINATION='platform=iOS Simulator,name=iPhone 17 Pro' ./scripts/capture-surfaces.sh
```

Do not commit `build/`, `build-DD/`, `Readiness.app`, or `Secrets.xcconfig`. The build recipe is `ReadinessTracker.xcodeproj` plus `scripts/*.sh`. There is no Makefile.

## Setup

- HealthKit on device. WHOOP data appears when the user shares WHOOP to Apple Health.
- Fitbit: copy `Secrets.xcconfig.example` to `Secrets.xcconfig`. See `FITBIT_SETUP.md` and `docs/DEVICE_SETUP.md`.
- App Group `group.com.readinesstracker` for widgets. See `docs/DEVICE_SETUP.md`.

## Honest gaps

1. ~~Fifth capture frame for Sleep HRV chips plus Sleep Quality / Consistency cards.~~ Closed — [verify-sleep-quality.png](.audit/verify-sleep-quality.png) from `testSleepQualitySurfaceVisibleAfterScroll`.
2. ~~Morning wraps on the half-width check-in card.~~ Closed — Morning/Evening use `lineLimit(1)` + `minimumScaleFactor` on the half-width cards.
3. ~~Center “90 READY” makes a larger inner hole than Fitness Summary, which has no center score.~~ Closed — tighter Activity packing (`size/10` stroke, gap 2) plus scaled center READY typography; see [verify-rings.png](.audit/verify-rings.png).
4. ~~Sleep Debt Status row was “Present further down | UITest” with no dedicated frame.~~ Closed — [verify-sleep-debt.png](.audit/verify-sleep-debt.png) from `testSleepDebtSurfaceVisibleAfterScroll`.
5. ~~Check-in tab had no dedicated UITest/PNG (only Today Morning/Evening cards).~~ Closed — [verify-checkin.png](.audit/verify-checkin.png) from `testCheckInTabSurface`.
6. ~~History tab had no dedicated UITest/PNG (only mentioned under Elsewhere).~~ Closed — [verify-history.png](.audit/verify-history.png) from `testHistoryTabSurface`.
7. ~~Journal “log 7 days” strip Status row cited `JournalView` with no PNG.~~ Closed — [verify-journal.png](.audit/verify-journal.png) from `testJournalSurface`.
