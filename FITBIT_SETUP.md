# Fitbit / Google Health API Setup (Honest #360–#366)

Legacy Fitbit Web API + Fitbit OAuth (FOT) are replaced by the **Google Health API**
and **Google OAuth 2.0**. ReadinessTracker's Fitbit data source authenticates with Google
and syncs **sleep**, **RHR / HRV / SpO2 / respiratory rate / sleep skin temp**, plus **steps** and **active calories**.

**Product labeling:** Settings / source picker still say **Fitbit** (`DataSource.fitbit`) for
minimal UI churn. Internally auth + sync are Google Health (`oauthType=google` in Keychain).

Docs:
- https://developers.google.com/health/about
- https://developers.google.com/health/setup
- https://developers.google.com/health/data-types/sleep
- https://developers.google.com/health/data-types/vitals
- https://developers.google.com/health/migration/api-specifications
- https://developers.google.com/identity/protocols/oauth2/native-app

## 1. Create a Google Cloud **iOS** OAuth client

1. Open [Google Health API setup](https://developers.google.com/health/setup) and enable the API.
2. Create an OAuth 2.0 Client ID of type **iOS**.
3. Bundle ID must match exactly: `com.readiness.ReadinessTracker`.
4. Note the **iOS Client ID** and the **iOS URL scheme** (reversed client ID) shown in Cloud Console
   (also as `REVERSED_CLIENT_ID` in a downloaded GoogleService-Info-style plist).
5. On **Data Access**, add scopes:
   - `https://www.googleapis.com/auth/googlehealth.sleep.readonly`
   - `https://www.googleapis.com/auth/googlehealth.health_metrics_and_measurements.readonly` (**Honest #362–#364 / #366** — RHR, HRV, SpO2, respiratory rate, sleep skin temp)
   - `https://www.googleapis.com/auth/googlehealth.activity_and_fitness.readonly` (**Honest #365** — required for `steps` + `active-energy-burned` dailyRollUp)
6. Under **Audience**, add yourself as a test user (unverified apps: **100-user** cap; Restricted
   scopes need later verification / CASA -- fine for personal use).
7. **After adding vitals and/or activity scopes:** disconnect Fitbit in Settings and **Connect** again so the
   consent screen grants the new Restricted scopes (older tokens soft-fail 403 on missing metrics).
8. Copy the **iOS Client ID**. Do **not** put a client secret in the iOS binary (PKCE public client).

### Redirect URI (Honest #361)

Google rejects custom schemes that do **not** contain a period (`readinesstracker://oauth` →
`400 invalid_request`). Use the reverse-client-ID form from the [native-app docs](https://developers.google.com/identity/protocols/oauth2/native-app):

```
com.googleusercontent.apps.<CLIENT_ID_PREFIX>:/oauth2redirect
```

where `<CLIENT_ID_PREFIX>` is the iOS client id **without** `.apps.googleusercontent.com`.

Example: client `123-abc.apps.googleusercontent.com`

- Scheme: `com.googleusercontent.apps.123-abc`
- Redirect: `com.googleusercontent.apps.123-abc:/oauth2redirect`

`FitbitManager` derives this at runtime from `GOOGLE_HEALTH_IOS_CLIENT_ID` for authorize + token
exchange. Info.plist must also register the same scheme via
`GOOGLE_HEALTH_IOS_REVERSED_CLIENT_ID` so `ASWebAuthenticationSession` can receive the callback.

Legacy `readinesstracker://oauth` stays registered for check-in / trends deep links and old tests,
but is **not** sent as OAuth `redirect_uri`.

## 2. Configure credentials locally (do not edit Swift with secrets)

1. Copy `Secrets.xcconfig.example` to `Secrets.xcconfig` (gitignored):
   ```bash
   cp Secrets.xcconfig.example Secrets.xcconfig
   ```
2. Fill in both keys:
   ```
   GOOGLE_HEALTH_IOS_CLIENT_ID = your_ios_client_id.apps.googleusercontent.com
   GOOGLE_HEALTH_IOS_REVERSED_CLIENT_ID = com.googleusercontent.apps.your_ios_client_id_prefix
   ```
3. Point the target's base configuration at `Secrets.xcconfig` (Debug & Release), or set the
   user-defined build settings. Info.plist maps `$(GOOGLE_HEALTH_IOS_CLIENT_ID)` and registers
   `$(GOOGLE_HEALTH_IOS_REVERSED_CLIENT_ID)` under `CFBundleURLTypes`.
4. Clean + rebuild.

`FitbitManager` reads `GOOGLE_HEALTH_IOS_CLIENT_ID` (then `GOOGLE_HEALTH_CLIENT_ID`, then
`FITBIT_CLIENT_ID`) from `Bundle.main`. Missing / placeholder -> clear setup `errorMessage`;
OAuth will not start.

## 3. What this build syncs

- Google OAuth 2.0 Authorization Code + **PKCE** (no client secret)
- Settings / Dashboard **Connect** uses `ASWebAuthenticationSession` (not bare `openURL`)
- Tokens in **Keychain** (`AfterFirstUnlockThisDeviceOnly`); never dual-link with legacy Fitbit tokens
- Identity bridge: `GET .../users/me/identity` (`legacyUserId` + `healthUserId`); **HTTP 412** ->
  clear "open Google Health / Fitbit app" message
- **Sleep** from `GET .../dataTypes/sleep/dataPoints` -> `DailyHealthData` / `DataStore` (`source: .fitbit`)
- **Resting HR** from `GET .../dataTypes/daily-resting-heart-rate/dataPoints` -> `DailyHealthData.restingHeartRate` (`source: .fitbit`) — needs vitals scope above
- **HRV (RMSSD)** from `GET .../dataTypes/daily-heart-rate-variability/dataPoints` -> `DailyHealthData.hrv` + `hrvIsRMSSD: true` (`source: .fitbit`) — **same** vitals scope as RHR (Honest #363); no new Console scope
- **SpO2** from `GET .../dataTypes/daily-oxygen-saturation/dataPoints` -> `DailyHealthData.bloodOxygen` (averagePercentage 0–100; `source: .fitbit`) — **same** vitals scope (Honest #364); no new Console scope
- **Steps** from `POST .../dataTypes/steps/dataPoints:dailyRollUp` -> `DailyHealthData.steps` (`countSum`; `source: .fitbit`) — needs **activity** scope (Honest #365)
- **Active calories** from `POST .../dataTypes/active-energy-burned/dataPoints:dailyRollUp` -> `DailyHealthData.activeCalories` (`kcalSum`; `source: .fitbit`) — same activity scope
- **Respiratory rate** from `GET .../dataTypes/daily-respiratory-rate/dataPoints` -> `DailyHealthData.respiratoryRate` (`breathsPerMinute`; `source: .fitbit`) — **same** vitals scope (Honest #366); no new Console scope
- **Sleep skin temperature** from `GET .../dataTypes/daily-sleep-temperature-derivations/dataPoints` -> `DailyHealthData.skinTemperature` (`nightlyTemperatureCelsius`; `source: .fitbit`) — **same** vitals scope (Honest #366); no new Console scope

## 4. Important notes

- Testing-mode refresh tokens expire after **~7 days** until the OAuth app is published
- Unverified apps: **100-user** limit
- Do **not** pass `include_granted_scopes` (legacy `fitness.*` must not mix with `googlehealth.*`)
- Prefer `ASWebAuthenticationSession` / system browser (no embedded WebViews)
- Completing Google connect clears any residual Fitbit Web API token state (no dual-link)
