import Foundation

@MainActor
class FitbitManager: ObservableObject {
    static let shared = FitbitManager()
    
    @Published var isAuthenticated = false
    @Published var latestData: DailyHealthData?
    @Published var errorMessage: String?
    
    private let clientId: String
    private let clientSecret: String
    private let redirectUri = "readinesstracker://oauth"
    private var accessToken: String?
    private var refreshToken: String?
    
    private init() {
        let id = (Bundle.main.object(forInfoDictionaryKey: "FITBIT_CLIENT_ID") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let secret = (Bundle.main.object(forInfoDictionaryKey: "FITBIT_CLIENT_SECRET") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        self.clientId = id
        self.clientSecret = secret
        if !Self.areCredentialsConfigured(clientId: id, clientSecret: secret) {
            errorMessage = "Fitbit credentials missing. Copy Secrets.xcconfig.example to Secrets.xcconfig, set FITBIT_CLIENT_ID and FITBIT_CLIENT_SECRET, and rebuild. See FITBIT_SETUP.md."
        }
    }

    private static func areCredentialsConfigured(clientId: String, clientSecret: String) -> Bool {
        guard !clientId.isEmpty, !clientSecret.isEmpty else { return false }
        let placeholders = [
            "YOUR_FITBIT_CLIENT_ID",
            "YOUR_FITBIT_CLIENT_SECRET",
            "YOUR_CLIENT_SECRET",
            "$(FITBIT_CLIENT_ID)",
            "$(FITBIT_CLIENT_SECRET)"
        ]
        if placeholders.contains(clientId) || placeholders.contains(clientSecret) {
            return false
        }
        if clientId.hasPrefix("YOUR_") || clientSecret.hasPrefix("YOUR_") {
            return false
        }
        return true
    }

    private var hasValidCredentials: Bool {
        Self.areCredentialsConfigured(clientId: clientId, clientSecret: clientSecret)
    }
    
    /// Builds the Fitbit OAuth URL, or nil when credentials are missing/placeholder.
    var authURL: URL? {
        guard hasValidCredentials else {
            errorMessage = "Fitbit credentials missing. Copy Secrets.xcconfig.example to Secrets.xcconfig, set FITBIT_CLIENT_ID and FITBIT_CLIENT_SECRET, and rebuild. See FITBIT_SETUP.md."
            return nil
        }
        var components = URLComponents(string: "https://www.fitbit.com/oauth2/authorize")!
        components.queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: redirectUri),
            URLQueryItem(name: "scope", value: "activity heartrate sleep")
        ]
        return components.url
    }
    
    func disconnect() {
        accessToken = nil
        refreshToken = nil
        isAuthenticated = false
        latestData = nil
        errorMessage = nil
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
        guard let url = URL(string: "https://api.fitbit.com/oauth2/token") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        guard hasValidCredentials else {
            errorMessage = "Fitbit credentials missing. Copy Secrets.xcconfig.example to Secrets.xcconfig, set FITBIT_CLIENT_ID and FITBIT_CLIENT_SECRET, and rebuild. See FITBIT_SETUP.md."
            return
        }
        let credentials = "\(clientId):\(clientSecret)".data(using: .utf8)!.base64EncodedString()
        request.setValue("Basic \(credentials)", forHTTPHeaderField: "Authorization")
        
        let body = "grant_type=authorization_code&code=\(code)&redirect_uri=\(redirectUri)"
        request.httpBody = body.data(using: .utf8)
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
            self.accessToken = tokenResponse.access_token
            self.refreshToken = tokenResponse.refresh_token
            self.isAuthenticated = true
            await fetchTodayData()
        } catch {
            errorMessage = "Token exchange failed: \(error.localizedDescription)"
        }
    }
    
    func fetchTodayData() async {
        guard let token = accessToken else { return }
        
        let date = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none)
        
        async let sleep = fetchSleep(token: token, date: date)
        async let heart = fetchHeartRate(token: token, date: date)
        async let activity = fetchActivity(token: token, date: date)
        
        let (sleepData, heartData, activityData) = await (sleep, heart, activity)
        
        let data = DailyHealthData(
            date: Date(),
            source: .fitbit,
            sleepHours: sleepData.hours,
            sleepEfficiency: sleepData.efficiency / 100,
            deepSleepPercent: 0.15,
            remSleepPercent: 0.20,
            hrv: heartData.hrv,
            restingHeartRate: heartData.restingHR,
            activeCalories: activityData.calories,
            steps: activityData.steps,
            workoutMinutes: activityData.activeMinutes
        )
        
        self.latestData = data
        DataStore.shared.save(data)
    }
    
    private func fetchSleep(token: String, date: String) async -> (hours: Double, efficiency: Double) {
        guard let url = URL(string: "https://api.fitbit.com/1.2/user/-/sleep/date/\(date).json") else {
            return (0, 0)
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(FitbitSleepResponse.self, from: data)
            guard let sleep = response.sleep.first else { return (0, 0) }
            let hours = Double(sleep.minutesAsleep) / 60
            return (hours, Double(sleep.efficiency))
        } catch {
            return (0, 0)
        }
    }
    
    private func fetchHeartRate(token: String, date: String) async -> (hrv: Double, restingHR: Double) {
        guard let url = URL(string: "https://api.fitbit.com/1/user/-/activities/heart/date/\(date)/1d.json") else {
            return (0, 60)
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(FitbitHeartResponse.self, from: data)
            let restingHR = response.activitiesHeart.first?.value.restingHeartRate ?? 60
            return (0, Double(restingHR))
        } catch {
            return (0, 60)
        }
    }
    
    private func fetchActivity(token: String, date: String) async -> (calories: Double, steps: Int, activeMinutes: Int) {
        guard let url = URL(string: "https://api.fitbit.com/1/user/-/activities/date/\(date).json") else {
            return (0, 0, 0)
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(FitbitActivityResponse.self, from: data)
            return (
                response.summary.caloriesOut,
                response.summary.steps,
                response.summary.veryActiveMinutes + response.summary.fairlyActiveMinutes
            )
        } catch {
            return (0, 0, 0)
        }
    }
}

struct TokenResponse: Codable {
    let access_token: String
    let refresh_token: String
    let expires_in: Int
}

struct FitbitSleepResponse: Codable {
    struct Sleep: Codable {
        let minutesAsleep: Int
        let efficiency: Int
    }
    let sleep: [Sleep]
}

struct FitbitHeartResponse: Codable {
    struct ActivityHeart: Codable {
        struct Value: Codable {
            let restingHeartRate: Int?
        }
        let value: Value
    }
    let activitiesHeart: [ActivityHeart]
}

struct FitbitActivityResponse: Codable {
    struct Summary: Codable {
        let caloriesOut: Double
        let steps: Int
        let veryActiveMinutes: Int
        let fairlyActiveMinutes: Int
    }
    let summary: Summary
}
