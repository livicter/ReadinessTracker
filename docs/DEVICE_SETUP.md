# Device & Developer Setup

## App Group (`group.com.readinesstracker`)

The iOS app, Home/Lock widgets, Watch App, and Watch complications share readiness scores via an App Group. **Portal enable is manual** (code + entitlements already declare the suite; live-device App Group does not work until these portal steps are done).

1. Sign in to [Apple Developer](https://developer.apple.com/account) → **Identifiers**.
2. Open the App ID for the main app (`com.readiness.ReadinessTracker`, or your team’s equivalent).
3. Enable **App Groups** → Configure → register / select `group.com.readinesstracker`.
4. Repeat for the Widget extension App ID (`com.readiness.ReadinessTracker.widget`), Watch App, and Watch Widgets extension App IDs.
5. In Xcode, confirm targets use the matching entitlements:
   - `ReadinessTracker/ReadinessTracker.entitlements`
   - `ReadinessTrackerWidget/ReadinessTrackerWidget.entitlements`
   - `ReadinessTrackerWatch Watch App/ReadinessTrackerWatch.entitlements`
   - `ReadinessTrackerWatchWidgets/ReadinessTrackerWatchWidgets.entitlements`
6. Rebuild on a physical device (or simulator) so `UserDefaults(suiteName: "group.com.readinesstracker")` works for Home/Lock widgets and Watch complications (`lastWatchSnapshot`).

Code path (Honest #36): iOS `WatchConnectivityManager` / `WidgetDataExporter` write `lastWatchSnapshot` via `WatchSnapshotAppGroupStore`; Watch `WatchSessionManager` mirrors the same key for the watch-side container. Do not claim live-device App Group works until portal steps above are complete.

## Fitbit credentials (no secrets in git)

1. Register a Fitbit app (see `FITBIT_SETUP.md`).
2. Copy `Secrets.xcconfig.example` → `Secrets.xcconfig` (gitignored).
3. Set `FITBIT_CLIENT_ID` and `FITBIT_CLIENT_SECRET` in `Secrets.xcconfig`.
4. Wire values into the app (pick one):
   - **Recommended:** Xcode → ReadinessTracker target → Build Settings → add user-defined settings `FITBIT_CLIENT_ID` / `FITBIT_CLIENT_SECRET` matching the xcconfig values, **or** set the target’s configuration file to `Secrets.xcconfig` for Debug and Release.
   - `ReadinessTracker/Info.plist` already contains `$(FITBIT_CLIENT_ID)` / `$(FITBIT_CLIENT_SECRET)`.
5. Clean build folder and rebuild. `FitbitManager` reads keys from `Bundle.main`; missing or `YOUR_FITBIT_*` placeholders set `errorMessage` and skip OAuth.

Do **not** paste secrets into `FitbitManager.swift` or commit `Secrets.xcconfig`.

## Lock Screen widgets

Supported families include `.accessoryCircular` and `.accessoryRectangular` (iOS 16+). After installing the widget extension on device, add them from the Lock Screen widget gallery.
