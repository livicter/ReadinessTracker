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

## 2. Update the Code
Open `ReadinessTracker/Services/FitbitManager.swift` and replace:
```swift
private let clientId = "YOUR_FITBIT_CLIENT_ID"
```
with your actual Client ID.

Also replace in `exchangeCodeForToken`:
```swift
let credentials = "\(clientId):YOUR_CLIENT_SECRET".data(using: .utf8)!.base64EncodedString()
```
with your actual Client Secret.

## 3. Important Notes
- Fitbit "Personal" apps are limited to 150 users max (fine for personal use)
- Read-Only access means we can only READ your data, not modify it
- The app will request these scopes: activity, heartrate, sleep
- Data refreshes when you open the app or pull-to-refresh
