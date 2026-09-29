# Fitbit / Google Health API Setup (Honest #360)

Legacy Fitbit Web API + Fitbit OAuth (FOT) are replaced by the **Google Health API**
and **Google OAuth 2.0**. ReadinessTracker's Fitbit data source authenticates with Google
and syncs **sleep** first.

**Product labeling:** Settings / source picker still say **Fitbit** (`DataSource.fitbit`) for
minimal UI churn. Internally auth + sync are Google Health (`oauthType=google` in Keychain).

Docs:
- https://developers.google.com/health/about
- https://developers.google.com/health/setup
- https://developers.google.com/health/data-types/sleep
- https://developers.google.com/health/migration/api-specifications
- https://developers.google.com/identity/protocols/oauth2/native-app

## 1. Create a Google Cloud **iOS** OAuth client

1. Open [Google Health API setup](https://developers.google.com/health/setup) and enable the API.
2. Create an OAuth 2.0 Client ID of type **iOS**.
3. Bundle ID must match exactly: `com.readiness.ReadinessTracker`.
4. Authorized redirect / custom URL scheme used by the app: `readinesstracker://oauth`
   (also register Google's reversed-client-id scheme if you use ASWebAuthenticationSession defaults).
5. On **Data Access**, add scope:
   - `https://www.googleapis.com/auth/googlehealth.sleep.readonly`
6. Under **Audience**, add yourself as a test user (unverified apps: **100-user** cap; Restricted
   scopes need later verification / CASA -- fine for personal use).
7. Copy the **iOS Client ID**. Do **not** put a client secret in the iOS binary (PKCE public client).

## 2. Configure credentials locally (do not edit Swift with secrets)

1. Copy `Secrets.xcconfig.example` to `Secrets.xcconfig` (gitignored):
   ```bash
   cp Secrets.xcconfig.example Secrets.xcconfig
   ```
2. Fill in:
   ```
   GOOGLE_HEALTH_IOS_CLIENT_ID = your_ios_client_id.apps.googleusercontent.com
   ```
3. Point the target's base configuration at `Secrets.xcconfig` (Debug & Release), or set the
   user-defined build setting. Info.plist maps `$(GOOGLE_HEALTH_IOS_CLIENT_ID)`.
4. Clean + rebuild.

`FitbitManager` reads `GOOGLE_HEALTH_IOS_CLIENT_ID` (then `GOOGLE_HEALTH_CLIENT_ID`, then
`FITBIT_CLIENT_ID`) from `Bundle.main`. Missing / placeholder -> clear setup `errorMessage`;
OAuth will not start.

## 3. What this build syncs

- Google OAuth 2.0 Authorization Code + **PKCE** (no client secret)
- Tokens in **Keychain** (`AfterFirstUnlockThisDeviceOnly`); never dual-link with legacy Fitbit tokens
- Identity bridge: `GET .../users/me/identity` (`legacyUserId` + `healthUserId`); **HTTP 412** ->
  clear "open Google Health / Fitbit app" message
- **Sleep** from `GET .../dataTypes/sleep/dataPoints` -> `DailyHealthData` / `DataStore` (`source: .fitbit`)
- Heart / activity / HRV / RHR / SpO2 Google Health sync **deferred** to later Honest PRs

## 4. Important notes

- Testing-mode refresh tokens expire after **~7 days** until the OAuth app is published
- Unverified apps: **100-user** limit
- Do **not** pass `include_granted_scopes` (legacy `fitness.*` must not mix with `googlehealth.*`)
- Prefer `ASWebAuthenticationSession` / system browser (no embedded WebViews)
- Completing Google connect clears any residual Fitbit Web API token state (no dual-link)
