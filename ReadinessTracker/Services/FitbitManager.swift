import Foundation
import Combine
import AuthenticationServices
import CryptoKit
import Security

/// Fitbit data source manager — backed by Google Health API (sleep-first).
/// User-facing product language stays "Fitbit" / `DataSource.fitbit`.
@MainActor
class FitbitManager: NSObject, ObservableObject {
    static let shared = FitbitManager()

    @Published var isAuthenticated = false
    @Published var latestData: DailyHealthData?
    @Published var errorMessage: String?

    private let clientId: String
    private let redirectUri = "readinesstracker://oauth"
    private let sleepScope = "https://www.googleapis.com/auth/googlehealth.sleep.readonly"
    private let authorizeEndpoint = "https://accounts.google.com/o/oauth2/v2/auth"
    private let tokenEndpoint = "https://oauth2.googleapis.com/token"
    private let revokeEndpoint = "https://oauth2.googleapis.com/revoke"
    private let identityURL = "https://health.googleapis.com/v4/users/me/identity"
    private let sleepListURL = "https://health.googleapis.com/v4/users/me/dataTypes/sleep/dataPoints"

    private var accessToken: String?
    private var refreshToken: String?
    private var tokenExpiry: Date?
    private var pendingCodeVerifier: String?
    private var authSession: ASWebAuthenticationSession?
    private var healthUserId: String?
    private var legacyUserId: String?

    private let keychain = GoogleHealthTokenKeychain()

    private override init() {
        // iOS public client: PKCE + Client ID only (no client secret in the binary).
        let id = Self.readInfoString(
            primary: "GOOGLE_HEALTH_IOS_CLIENT_ID",
            aliases: ["GOOGLE_HEALTH_CLIENT_ID", "FITBIT_CLIENT_ID"]
        )
        self.clientId = id
        super.init()

        if !Self.areCredentialsConfigured(clientId: id) {
            errorMessage = Self.missingCredentialsMessage
        }

        if let stored = keychain.load() {
            accessToken = stored.accessToken
            refreshToken = stored.refreshToken
            tokenExpiry = stored.expiry
            healthUserId = stored.healthUserId
            legacyUserId = stored.legacyUserId
            isAuthenticated = stored.accessToken != nil || stored.refreshToken != nil
        }
    }

    private static let missingCredentialsMessage =
        "Fitbit isn’t set up on this build yet. Add GOOGLE_HEALTH_IOS_CLIENT_ID to Secrets.xcconfig."

    private static func readInfoString(primary: String, aliases: [String]) -> String {
        let keys = [primary] + aliases
        for key in keys {
            if let raw = Bundle.main.object(forInfoDictionaryKey: key) as? String {
                let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty { return trimmed }
            }
        }
        return ""
    }

    private static func areCredentialsConfigured(clientId: String) -> Bool {
        guard !clientId.isEmpty else { return false }
        let placeholders = [
            "YOUR_FITBIT_CLIENT_ID",
            "YOUR_GOOGLE_HEALTH_CLIENT_ID",
            "YOUR_GOOGLE_HEALTH_IOS_CLIENT_ID",
            "YOUR_CLIENT_ID",
            "$(FITBIT_CLIENT_ID)",
            "$(GOOGLE_HEALTH_CLIENT_ID)",
            "$(GOOGLE_HEALTH_IOS_CLIENT_ID)"
        ]
        if placeholders.contains(clientId) { return false }
        if clientId.hasPrefix("YOUR_") { return false }
        if clientId.hasPrefix("$(") { return false }
        return true
    }

    private var hasValidCredentials: Bool {
        Self.areCredentialsConfigured(clientId: clientId)
    }

    /// Builds the Google OAuth URL (PKCE), or nil when credentials are missing/placeholder.
    var authURL: URL? {
        guard hasValidCredentials else {
            errorMessage = Self.missingCredentialsMessage
            return nil
        }
        let verifier = PKCE.makeCodeVerifier()
        pendingCodeVerifier = verifier
        var components = URLComponents(string: authorizeEndpoint)!
        components.queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: redirectUri),
            URLQueryItem(name: "scope", value: sleepScope),
            URLQueryItem(name: "access_type", value: "offline"),
            URLQueryItem(name: "code_challenge", value: PKCE.codeChallengeS256(for: verifier)),
            URLQueryItem(name: "code_challenge_method", value: "S256")
            // Do NOT pass include_granted_scopes — mixing legacy fitness.* scopes breaks Health API.
        ]
        return components.url
    }

    /// Prefer ASWebAuthenticationSession when a presentation context is available.
    func startAuthentication(anchorProvider: ASWebAuthenticationPresentationContextProviding) {
        guard let url = authURL else { return }
        let session = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: "readinesstracker"
        ) { [weak self] callbackURL, error in
            Task { @MainActor in
                guard let self else { return }
                if let error {
                    // User cancel is quiet; other failures surface.
                    let ns = error as NSError
                    if ns.domain == ASWebAuthenticationSessionError.errorDomain,
                       ns.code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                        return
                    }
                    self.errorMessage = "Sign-in failed: \(error.localizedDescription)"
                    return
                }
                guard let callbackURL else {
                    self.errorMessage = "No callback from Google sign-in"
                    return
                }
                self.handleCallback(url: callbackURL)
            }
        }
        session.presentationContextProvider = anchorProvider
        session.prefersEphemeralWebBrowserSession = false
        authSession = session
        _ = session.start()
    }

    func disconnect() {
        let tokenToRevoke = accessToken ?? refreshToken
        accessToken = nil
        refreshToken = nil
        tokenExpiry = nil
        pendingCodeVerifier = nil
        healthUserId = nil
        legacyUserId = nil
        isAuthenticated = false
        latestData = nil
        errorMessage = hasValidCredentials ? nil : Self.missingCredentialsMessage
        keychain.clear()
        clearLegacyFitbitAuthState()
        if let tokenToRevoke {
            Task { await Self.revokeGoogleToken(tokenToRevoke) }
        }
    }

    /// Hard rule: never dual-link Fitbit Web API tokens with Google Health.
    /// Completing Google OAuth clears any residual legacy Fitbit OAuth state.
    private func clearLegacyFitbitAuthState() {
        LegacyFitbitTokenStore.clear()
    }

    private static func revokeGoogleToken(_ token: String) async {
        guard let url = URL(string: "https://oauth2.googleapis.com/revoke") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = "token=\(token.addingPercentEncoding(withAllowedCharacters: CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")) ?? token)".data(using: .utf8)
        _ = try? await URLSession.shared.data(for: request)
    }

    func handleCallback(url: URL) {
        guard let code = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?.first(where: { $0.name == "code" })?.value else {
            errorMessage = "No auth code in callback"
            return
        }
        Task {
            await exchangeCodeForToken(code: code)
        }
    }

    private func exchangeCodeForToken(code: String) async {
        guard hasValidCredentials else {
            errorMessage = Self.missingCredentialsMessage
            return
        }
        guard let url = URL(string: tokenEndpoint) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        var params: [String: String] = [
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": redirectUri,
            "client_id": clientId
        ]
        if let verifier = pendingCodeVerifier {
            params["code_verifier"] = verifier
        }
        // iOS public client: PKCE only — never send a client_secret from the app binary.

        request.httpBody = Self.formURLEncoded(params).data(using: .utf8)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                let body = String(data: data, encoding: .utf8) ?? ""
                errorMessage = "Token exchange failed (\(http.statusCode)): \(body.prefix(200))"
                return
            }
            let tokenResponse = try JSONDecoder().decode(GoogleOAuthTokenResponse.self, from: data)
            // Never dual-link: Google connect clears any residual Fitbit Web API tokens first.
            clearLegacyFitbitAuthState()
            applyTokenResponse(tokenResponse)
            pendingCodeVerifier = nil
            isAuthenticated = true
            errorMessage = nil
            let identityOK = await fetchAndStoreIdentity()
            if identityOK {
                await fetchTodayData()
            }
        } catch {
            errorMessage = "Token exchange failed: \(error.localizedDescription)"
        }
    }

    private func applyTokenResponse(_ tokenResponse: GoogleOAuthTokenResponse) {
        accessToken = tokenResponse.access_token
        if let refresh = tokenResponse.refresh_token, !refresh.isEmpty {
            refreshToken = refresh
        }
        let expires = tokenResponse.expires_in ?? 3600
        tokenExpiry = Date().addingTimeInterval(TimeInterval(expires))
        persistKeychain()
    }

    private func persistKeychain() {
        keychain.save(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiry: tokenExpiry,
            healthUserId: healthUserId,
            legacyUserId: legacyUserId,
            oauthType: "google"
        )
    }

    /// Bridge legacy Fitbit id ↔ Google Health id. HTTP 412 = no Google Health profile yet.
    @discardableResult
    private func fetchAndStoreIdentity() async -> Bool {
        guard let token = await ensureAccessToken(),
              let url = URL(string: identityURL) else { return false }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse {
                if http.statusCode == 412 {
                    errorMessage = "No Google Health profile yet. Open the Google Health / Fitbit app, finish setup, then reconnect."
                    return false
                }
                if !(200...299).contains(http.statusCode) {
                    let body = String(data: data, encoding: .utf8) ?? ""
                    errorMessage = "Identity lookup failed (\(http.statusCode)): \(body.prefix(160))"
                    return false
                }
            }
            let identity = try JSONDecoder().decode(GoogleHealthIdentity.self, from: data)
            healthUserId = identity.healthUserId
            legacyUserId = identity.legacyUserId
            persistKeychain()
            return true
        } catch {
            errorMessage = "Identity lookup failed: \(error.localizedDescription)"
            return false
        }
    }

    private func ensureAccessToken() async -> String? {
        if let token = accessToken, let expiry = tokenExpiry, expiry > Date().addingTimeInterval(60) {
            return token
        }
        if let token = accessToken, tokenExpiry == nil {
            return token
        }
        guard let refresh = refreshToken else { return accessToken }
        return await refreshAccessToken(using: refresh)
    }

    private func refreshAccessToken(using refresh: String) async -> String? {
        guard hasValidCredentials, let url = URL(string: tokenEndpoint) else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let params: [String: String] = [
            "grant_type": "refresh_token",
            "refresh_token": refresh,
            "client_id": clientId
        ]
        request.httpBody = Self.formURLEncoded(params).data(using: .utf8)
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                errorMessage = "Token refresh failed (\(http.statusCode))"
                return nil
            }
            let tokenResponse = try JSONDecoder().decode(GoogleOAuthTokenResponse.self, from: data)
            applyTokenResponse(tokenResponse)
            return accessToken
        } catch {
            errorMessage = "Token refresh failed: \(error.localizedDescription)"
            return nil
        }
    }

    func fetchTodayData() async {
        guard let token = await ensureAccessToken() else {
            if hasValidCredentials {
                errorMessage = "Not signed in to Fitbit (Google Health)."
            }
            return
        }

        let sleepResult = await fetchSleep(token: token)
        // Heart / activity deferred to later Honest PRs — keep compiling with clear stub.
        let heartUnavailable = "Heart rate via Google Health not enabled in this build yet."
        let activityUnavailable = "Activity via Google Health not enabled in this build yet."
        _ = heartUnavailable
        _ = activityUnavailable

        guard let sleep = sleepResult else {
            if errorMessage == nil {
                errorMessage = "No sleep session found for today."
            }
            return
        }

        let data = DailyHealthData(
            date: Date(),
            source: .fitbit,
            sleepHours: sleep.hours,
            sleepEfficiency: sleep.efficiency,
            deepSleepPercent: sleep.deepPercent,
            remSleepPercent: sleep.remPercent,
            lightSleepPercent: sleep.lightPercent,
            awakePercent: sleep.awakePercent,
            sleepOnsetMinutes: sleep.onsetMinutes,
            sleepStartTime: sleep.start,
            sleepEndTime: sleep.end,
            wakeEpisodes: sleep.wakeEpisodes,
            sleepStages: sleep.stages,
            hrv: 0,
            restingHeartRate: 0,
            activeCalories: 0,
            steps: 0,
            workoutMinutes: 0
        )

        self.latestData = data
        DataStore.shared.save(data)
        errorMessage = nil
    }

    private func fetchSleep(token: String) async -> GoogleHealthSleepMapper.MappedSleep? {
        let cal = Calendar.current
        let startOfToday = cal.startOfDay(for: Date())
        let startOfTomorrow = cal.date(byAdding: .day, value: 1, to: startOfToday) ?? startOfToday.addingTimeInterval(86400)
        // Sleep is filtered by session end time (wake) in the user's day window.
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime]
        let filter = "sleep.interval.end_time >= \"\(iso.string(from: startOfToday))\" AND sleep.interval.end_time < \"\(iso.string(from: startOfTomorrow))\""

        var components = URLComponents(string: sleepListURL)!
        components.queryItems = [
            URLQueryItem(name: "filter", value: filter),
            URLQueryItem(name: "pageSize", value: "25")
        ]
        guard let url = components.url else { return nil }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse {
                if http.statusCode == 412 {
                    errorMessage = "No Google Health profile yet. Open the Google Health / Fitbit app, finish setup, then reconnect."
                    return nil
                }
                if !(200...299).contains(http.statusCode) {
                    let body = String(data: data, encoding: .utf8) ?? ""
                    errorMessage = "Sleep sync failed (\(http.statusCode)): \(body.prefix(180))"
                    return nil
                }
            }
            return try GoogleHealthSleepMapper.mapListResponse(data)
        } catch {
            errorMessage = "Sleep sync failed: \(error.localizedDescription)"
            return nil
        }
    }

    private static func formURLEncoded(_ params: [String: String]) -> String {
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")
        return params
            .map { key, value in
                let k = key.addingPercentEncoding(withAllowedCharacters: allowed) ?? key
                let v = value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
                return "\(k)=\(v)"
            }
            .joined(separator: "&")
    }
}

// MARK: - PKCE

enum PKCE {
    static func makeCodeVerifier() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes)
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    static func codeChallengeS256(for verifier: String) -> String {
        let digest = SHA256.hash(data: Data(verifier.utf8))
        return Data(digest)
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

// MARK: - Token models / Keychain

struct GoogleOAuthTokenResponse: Codable {
    let access_token: String
    let refresh_token: String?
    let expires_in: Int?
    let token_type: String?
    let scope: String?
}

struct GoogleHealthIdentity: Codable {
    let legacyUserId: String?
    let healthUserId: String?
}

/// Cleared on Google Health connect — never dual-link with Google OAuth.
enum LegacyFitbitTokenStore {
    private static let service = "com.readinesstracker.fitbit.legacy"
    private static let account = "oauth"

    static func clear() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
        // Also wipe any accidental UserDefaults leftovers from older builds.
        UserDefaults.standard.removeObject(forKey: "fitbit_access_token")
        UserDefaults.standard.removeObject(forKey: "fitbit_refresh_token")
    }
}

struct GoogleHealthTokenKeychain {
    private let service = "com.readinesstracker.googlehealth"
    private let account = "oauth"

    struct Stored {
        var accessToken: String?
        var refreshToken: String?
        var expiry: Date?
        var healthUserId: String?
        var legacyUserId: String?
        var oauthType: String?
    }

    func save(
        accessToken: String?,
        refreshToken: String?,
        expiry: Date?,
        healthUserId: String? = nil,
        legacyUserId: String? = nil,
        oauthType: String? = "google"
    ) {
        var payload: [String: Any] = [:]
        if let accessToken { payload["accessToken"] = accessToken }
        if let refreshToken { payload["refreshToken"] = refreshToken }
        if let expiry { payload["expiry"] = expiry.timeIntervalSince1970 }
        if let healthUserId { payload["healthUserId"] = healthUserId }
        if let legacyUserId { payload["legacyUserId"] = legacyUserId }
        if let oauthType { payload["oauthType"] = oauthType }
        guard let data = try? JSONSerialization.data(withJSONObject: payload) else { return }
        clear()
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    func load() -> Stored? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        var stored = Stored()
        stored.accessToken = json["accessToken"] as? String
        stored.refreshToken = json["refreshToken"] as? String
        if let ts = json["expiry"] as? Double {
            stored.expiry = Date(timeIntervalSince1970: ts)
        }
        stored.healthUserId = json["healthUserId"] as? String
        stored.legacyUserId = json["legacyUserId"] as? String
        stored.oauthType = json["oauthType"] as? String
        return stored
    }

    func clear() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Google Health sleep JSON → app model

enum GoogleHealthSleepMapper {
    struct MappedSleep {
        var hours: Double
        var efficiency: Double
        var deepPercent: Double
        var remPercent: Double
        var lightPercent: Double
        var awakePercent: Double
        var onsetMinutes: Double
        var start: Date?
        var end: Date?
        var wakeEpisodes: Int
        var stages: [SleepStageInterval]
    }

    struct ListResponse: Codable {
        let dataPoints: [DataPoint]?
        let nextPageToken: String?
    }

    struct DataPoint: Codable {
        let name: String?
        let sleep: SleepPayload?
    }

    struct SleepPayload: Codable {
        let interval: SessionInterval?
        let type: String?
        let stages: [StagePayload]?
        let summary: SleepSummary?
        let metadata: SleepMetadata?
    }

    struct SessionInterval: Codable {
        let startTime: String?
        let endTime: String?
        let startUtcOffset: String?
        let endUtcOffset: String?
    }

    struct StagePayload: Codable {
        let startTime: String?
        let endTime: String?
        let type: String?
    }

    struct SleepSummary: Codable {
        let stagesSummary: [StageSummary]?
        let minutesInSleepPeriod: FlexibleInt64?
        let minutesAfterWakeUp: FlexibleInt64?
        let minutesToFallAsleep: FlexibleInt64?
        let minutesAsleep: FlexibleInt64?
        let minutesAwake: FlexibleInt64?
    }

    struct StageSummary: Codable {
        let type: String?
        let minutes: FlexibleInt64?
        let count: FlexibleInt64?
    }

    struct SleepMetadata: Codable {
        let nap: Bool?
        let processed: Bool?
        let manuallyEdited: Bool?
    }

    /// Google Health often encodes int64 fields as JSON strings.
    struct FlexibleInt64: Codable {
        let value: Int64
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let i = try? container.decode(Int64.self) {
                value = i
            } else if let s = try? container.decode(String.self), let i = Int64(s) {
                value = i
            } else if let d = try? container.decode(Double.self) {
                value = Int64(d)
            } else {
                value = 0
            }
        }
        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(String(value))
        }
    }

    static func mapListResponse(_ data: Data) throws -> MappedSleep? {
        let decoded = try JSONDecoder().decode(ListResponse.self, from: data)
        guard let points = decoded.dataPoints, !points.isEmpty else { return nil }
        // Prefer longest non-nap session ending today.
        let candidates = points.compactMap { $0.sleep }
        guard let best = pickMainSleep(from: candidates) else { return nil }
        return mapSleep(best)
    }

    static func pickMainSleep(from sleeps: [SleepPayload]) -> SleepPayload? {
        let nonNaps = sleeps.filter { $0.metadata?.nap != true }
        let pool = nonNaps.isEmpty ? sleeps : nonNaps
        return pool.max { a, b in
            let aMin = a.summary?.minutesAsleep?.value ?? durationMinutes(a.interval)
            let bMin = b.summary?.minutesAsleep?.value ?? durationMinutes(b.interval)
            return aMin < bMin
        }
    }

    static func durationMinutes(_ interval: SessionInterval?) -> Int64 {
        guard let start = parseTime(interval?.startTime),
              let end = parseTime(interval?.endTime) else { return 0 }
        return Int64(end.timeIntervalSince(start) / 60)
    }

    static func mapSleep(_ sleep: SleepPayload) -> MappedSleep {
        let start = parseTime(sleep.interval?.startTime)
        let end = parseTime(sleep.interval?.endTime)
        let stages = (sleep.stages ?? []).compactMap { stage -> SleepStageInterval? in
            guard let s = parseTime(stage.startTime),
                  let e = parseTime(stage.endTime),
                  let mapped = mapStageType(stage.type) else { return nil }
            return SleepStageInterval(stage: mapped, startDate: s, endDate: e)
        }

        let minutesAsleep = Double(sleep.summary?.minutesAsleep?.value ?? 0)
        let minutesInBed = Double(sleep.summary?.minutesInSleepPeriod?.value ?? 0)
        let hours: Double = {
            if minutesAsleep > 0 { return minutesAsleep / 60 }
            if let start, let end { return max(0, end.timeIntervalSince(start) / 3600) }
            return 0
        }()

        let efficiency: Double = {
            if minutesInBed > 0, minutesAsleep > 0 {
                return min(1, max(0, minutesAsleep / minutesInBed))
            }
            // Fallback: compute from stages if present.
            let asleep = stages.filter { $0.stage != .awake }.reduce(0.0) { $0 + $1.durationMinutes }
            let total = stages.reduce(0.0) { $0 + $1.durationMinutes }
            guard total > 0 else { return 0.85 }
            return min(1, max(0, asleep / total))
        }()

        func minutes(for type: String) -> Double {
            let needle = type.uppercased()
            if let summary = sleep.summary?.stagesSummary?
                .first(where: { ($0.type ?? "").uppercased() == needle })?.minutes?.value {
                return Double(summary)
            }
            // Fall back to raw stage payloads (match API type string, avoid double-count via SleepStage aliases).
            return (sleep.stages ?? []).reduce(0.0) { partial, stage in
                guard (stage.type ?? "").uppercased() == needle,
                      let s = parseTime(stage.startTime),
                      let e = parseTime(stage.endTime) else { return partial }
                return partial + e.timeIntervalSince(s) / 60
            }
        }

        let deepMin = minutes(for: "DEEP")
        let remMin = minutes(for: "REM")
        let lightMin = minutes(for: "LIGHT") + minutes(for: "ASLEEP")
        let awakeMin = minutes(for: "AWAKE") + minutes(for: "RESTLESS")
        let denom = max(minutesAsleep > 0 ? minutesAsleep : (deepMin + remMin + lightMin), 1)

        let wakeEpisodes = stages.filter { $0.stage == .awake }.count

        return MappedSleep(
            hours: hours,
            efficiency: efficiency,
            deepPercent: deepMin / denom,
            remPercent: remMin / denom,
            lightPercent: lightMin / denom,
            awakePercent: awakeMin / max(minutesInBed > 0 ? minutesInBed : denom, 1),
            onsetMinutes: Double(sleep.summary?.minutesToFallAsleep?.value ?? 0),
            start: start,
            end: end,
            wakeEpisodes: wakeEpisodes,
            stages: stages
        )
    }

    static func mapStageType(_ raw: String?) -> SleepStage? {
        guard let raw else { return nil }
        switch raw.uppercased() {
        case "AWAKE", "RESTLESS": return .awake
        case "LIGHT", "ASLEEP": return .light
        case "DEEP": return .deep
        case "REM": return .rem
        default: return nil
        }
    }

    static func parseTime(_ raw: String?) -> Date? {
        guard let raw, !raw.isEmpty else { return nil }
        let isoFrac = ISO8601DateFormatter()
        isoFrac.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = isoFrac.date(from: raw) { return d }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime]
        return iso.date(from: raw)
    }
}
