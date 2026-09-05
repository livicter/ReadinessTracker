# ReadinessTracker

iOS readiness app. Bright Apple Health UI. Local HealthKit + optional Fitbit. WHOOP product surfaces via Apple Health. No unofficial WHOOP OAuth.

**main today:** `ea79681` (PR #12). Body sits above the WHOOP stack. Today shows sleep disturbance count. Journal impact waits for 7 days.

Screenshots below are live Simulator captures from `./scripts/capture-surfaces.sh` (XCUITest swipe + `-ui-fixture`, not VoiceOver).

## Status

| Surface | Status | Evidence |
|---|---|---|
| Today hero, Gym / Work / Sleep rings | Shipped on main | [verify-dashboard.png](.audit/verify-dashboard.png) |
| Source chips + **WHOOP via Apple Health** | Shipped on main | dashboard frame |
| Morning / Evening check-in cards | Shipped. Tab bar covers them in the dashboard shot. Morning wraps on the half-card | dashboard + body frames |
| Recovery / Strain wheel | Shipped on main | [verify-whoop-stack.png](.audit/verify-whoop-stack.png) |
| Sleep Performance (14-night need) | Shipped. Efficiency and Consistency are one line | whoop frame |
| Sleep HRV (RMSSD) | Shipped. Header and 58 ms in the whoop frame. Trend / Sleep Quality chips sit below the chart, under the tab bar | whoop frame |
| Sleep Debt | Present further down | UITest, not this PNG |
| Sleep Quality / Consistency cards | Present further down. One iPhone frame cannot hold Recovery through Consistency | UITest |
| Body & activity (steps, Activity min, calories, SpO2, water, caffeine, protein) | Shipped on main, **above** the WHOOP stack. Label is Activity, not Heart Points | [verify-body-activity.png](.audit/verify-body-activity.png) |
| Sleep disturbance count on Today sleep row | Shipped on main | `DashboardView` sleep card. Not in the four PNGs |
| Journal “log 7 days” strip | Shipped on main | `JournalView`. Not in the four PNGs |
| Settings connect / reconnect + cycle toggle off | Shipped on main | [verify-settings-sources.png](.audit/verify-settings-sources.png) |
| Official WHOOP API | Out of scope | Settings copy says so |
| Google Fit REST / “Heart Points” | Out of scope | Activity = minutes + calories |

## App surfaces

### Today

Bright grouped background, dark selected Apple Watch chip, WHOOP-via-Health caption, readiness 90 / Ready to perform.

![Today dashboard](.audit/verify-dashboard.png)

### Recovery, sleep performance, HRV

Scrolled Today after Body. Need caption is the 14-night average. Efficiency and Consistency no longer wrap mid-word.

![WHOOP stack](.audit/verify-whoop-stack.png)

### Body and activity

Sits above Recovery & Strain. Label is **Activity**, not Heart Points. Protein row clips under the tab bar.

![Body and activity](.audit/verify-body-activity.png)

### Settings — data sources

Apple Health connected + Reconnect. Fitbit Connect with missing-secrets error (expected without `Secrets.xcconfig`). Cycle tracking off.

![Settings data sources](.audit/verify-settings-sources.png)

## Verify

```bash
# Unit gate (CI)
DESTINATION='platform=iOS Simulator,name=iPhone 17 Pro' ./scripts/ci-verify.sh

# Scrolled surfaces → .audit/verify-*.png
./scripts/capture-surfaces.sh
```

`ci-verify.sh` runs `ReadinessTrackerTests` only. UI tests are `ReadinessTrackerUITests` (4/4 on iPhone 17 Pro when last captured).

## Setup

- HealthKit on device. WHOOP data appears when the user shares WHOOP → Apple Health.
- Fitbit: copy `Secrets.xcconfig.example` → `Secrets.xcconfig`. See `FITBIT_SETUP.md` and `docs/DEVICE_SETUP.md`.
- App Group `group.com.readinesstracker` for widgets. See `docs/DEVICE_SETUP.md`.

## Honest gaps (next swarm)

1. Fifth capture frame for Sleep HRV chips plus Sleep Quality / Consistency cards, or keep UITest-only proof for that slice.
2. Tab bar is a floating overlay. Check-in cards sit under it in the dashboard shot (scroll 40pt or shrink the hero).
3. Morning wraps on the half-width check-in card.
