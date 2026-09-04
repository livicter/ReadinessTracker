# Fitbit App Registration Step-by-Step

## 1. Register a Fitbit App
1. Go to https://dev.fitbit.com/login
2. Sign in with your Fitbit account (or create one)
3. Click "Register a New App"
4. Fill in the form:
   - **Application Name**: ReadinessTracker
   - **Description**: Personal fitness readiness tracker
   - **Application Website**: https://localhost (placeholder)
   - **Organization**: Your name
   - **Organization Website**: https://localhost
   - **Terms of Service URL**: https://localhost
   - **Privacy Policy URL**: https://localhost
   - **OAuth 2.0 Application Type**: Personal
   - **Callback URL**: readinesstracker://oauth
   - **Default Access Type**: Read-Only

5. Click "Register"
6. You will get:
   - **Client ID**: Copy this
   - **Client Secret**: Copy this (click to reveal)

## 2. Configure credentials locally (do not edit Swift with secrets)

Secrets must **not** live in git or in `FitbitManager.swift`.

1. Copy `Secrets.xcconfig.example` to `Secrets.xcconfig` (already gitignored):
   ```bash
   cp Secrets.xcconfig.example Secrets.xcconfig
   ```
2. Fill in:
   ```
   FITBIT_CLIENT_ID = your_client_id_here
   FITBIT_CLIENT_SECRET = your_client_secret_here
   ```
3. Ensure Xcode passes them into Info.plist:
   - `ReadinessTracker/Info.plist` maps:
     - `FITBIT_CLIENT_ID` → `$(FITBIT_CLIENT_ID)`
     - `FITBIT_CLIENT_SECRET` → `$(FITBIT_CLIENT_SECRET)`
   - Set those build settings on the ReadinessTracker target (user-defined), **or** point the target’s base configuration at `Secrets.xcconfig` for Debug and Release.
4. Clean + rebuild.

`FitbitManager` reads `FITBIT_CLIENT_ID` / `FITBIT_CLIENT_SECRET` from `Bundle.main`. If they are missing or still placeholders (`YOUR_FITBIT_*`), it sets a clear `errorMessage` and will **not** start OAuth.

Also see `docs/DEVICE_SETUP.md` for App Group + credential wiring.

## 3. Important Notes
- Fitbit "Personal" apps are limited to 150 users max (fine for personal use)
- Read-Only access means we can only READ your data, not modify it
- The app will request these scopes: activity, heartrate, sleep
- Data refreshes when you open the app or pull-to-refresh
