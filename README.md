# ReadinessTracker

iOS readiness app. Bright Apple Health UI. Local HealthKit + optional Fitbit. WHOOP product surfaces via Apple Health — no unofficial WHOOP OAuth.

**main today:** `d2ae376` (PR #8 harness on top of PR #7).  
**Stacked but not on main:** PR #9 (disturbances + journal strip) and PR #10 (Body above WHOOP) merged into `feature/body-above-whoop`. Open a PR from that branch onto `main` before treating those slices as shipped.

Screenshots below are live Simulator captures from `./scripts/capture-surfaces.sh` (XCUITest swipe + `-ui-fixture`, not VoiceOver). Re-run that script after landing #9/#10; do not enable Simulator Accessibility to prove these surfaces.

## Status

| Surface | Status | Evidence |
|---|---|---|
| Today hero, Gym / Work / Sleep rings | Shipped on main | [verify-dashboard.png](.audit/verify-dashboard.png) |
| Source chips + **WHOOP via Apple Health** | Shipped on main | dashboard frame |
| Morning / Evening check-in cards | Shipped; sit under the hero (tab bar covers the bottom of the dashboard shot) | dashboard frame |
| Recovery / Strain wheel | Shipped on main | [verify-whoop-stack.png](.audit/verify-whoop-stack.png) |
| Sleep Performance (14-night need) | Shipped on main | whoop frame |
| Sleep HRV (RMSSD) | Shipped on main | whoop frame, 58 ms fixture |
| Sleep Debt | Shipped; only the header is in the whoop frame | whoop frame bottom edge |
| Sleep Quality / Consistency cards | Present; further down. UITest asserts labels after swipe. One iPhone frame cannot hold Recovery → Consistency | UITest, not a single PNG |
| Body & activity (steps, Activity min, calories, SpO2, water, caffeine, protein) | Shipped on main, **still below WHOOP** until PR #10 is on main | [verify-body-activity.png](.audit/verify-body-activity.png) |
| Sleep disturbance count on Today sleep row | PR #9, not on main | code on `feature/whoop-today-completeness` |
| Journal “log 7 days” strip | PR #9, not on main | same branch |
| Settings connect / reconnect + cycle toggle off | Shipped on main | [verify-settings-sources.png](.audit/verify-settings-sources.png) |
| Official WHOOP API | Out of scope | Settings copy says so |
| Google Fit REST / “Heart Points” | Out of scope | Activity = minutes + calories |

## App surfaces

### Today

Bright grouped background, dark selected Apple Watch chip, WHOOP-via-Health caption, readiness 90 / Ready to perform.

![Today dashboard](.audit/verify-dashboard.png)

### Recovery, sleep performance, HRV

Scrolled Today. Need caption is the 14-night average. Sleep Debt starts under the tab bar.

![WHOOP stack](.audit/verify-whoop-stack.png)

### Body and activity

Google Health–style glance metrics. Label is **Activity**, not Heart Points. Protein row clips on this fixture width.

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

1. Land `feature/body-above-whoop` onto `main` (PRs #9 + #10).
2. Recapture all four PNGs after the section reorder.
3. Compact Sleep Performance / HRV sublabels so “Efficiency” and “Sleep Quality” do not wrap mid-word.
4. Fifth capture frame for Sleep Quality + Consistency, or accept UITest-only proof for that slice.
5. Tab bar is a floating overlay; keep check-in cards out from under it in the dashboard shot (scroll 40pt or shrink hero).
