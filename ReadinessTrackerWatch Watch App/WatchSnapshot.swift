import Foundation

/// Snapshot of today's metrics pushed from the iPhone via WatchConnectivity.
/// Dictionary keys must match `WatchConnectivityManager.Key` in the iOS target.
struct WatchSnapshot: Equatable {
    let date: Date
    let readiness: Int
    let recovery: Int
    let strain: Double          // WHOOP-style 0-21
    let sleepHours: Double
    let sleepEfficiency: Double // 0-1
    let deepSleepPercent: Double
    let remSleepPercent: Double
    let hrv: Double             // ms
    let restingHeartRate: Double
    let activeCalories: Double
    let steps: Int
    let workoutMinutes: Int
    let checkedInMorning: Bool
    let sourceName: String

    init(dictionary: [String: Any]) {
        date = Date(timeIntervalSince1970: dictionary["date"] as? TimeInterval ?? Date().timeIntervalSince1970)
        readiness = dictionary["readiness"] as? Int ?? 0
        recovery = dictionary["recovery"] as? Int ?? 0
        strain = dictionary["strain"] as? Double ?? 0
        sleepHours = dictionary["sleepHours"] as? Double ?? 0
        sleepEfficiency = dictionary["sleepEfficiency"] as? Double ?? 0
        deepSleepPercent = dictionary["deepSleepPercent"] as? Double ?? 0
        remSleepPercent = dictionary["remSleepPercent"] as? Double ?? 0
        hrv = dictionary["hrv"] as? Double ?? 0
        restingHeartRate = dictionary["restingHeartRate"] as? Double ?? 0
        activeCalories = dictionary["activeCalories"] as? Double ?? 0
        steps = dictionary["steps"] as? Int ?? 0
        workoutMinutes = dictionary["workoutMinutes"] as? Int ?? 0
        checkedInMorning = dictionary["checkedInMorning"] as? Bool ?? false
        sourceName = dictionary["sourceName"] as? String ?? ""
    }

    /// Demo data for previews and the unpaired empty state.
    static let sample = WatchSnapshot(dictionary: [
        "date": Date().timeIntervalSince1970,
        "readiness": 82,
        "recovery": 78,
        "strain": 11.4,
        "sleepHours": 7.4,
        "sleepEfficiency": 0.91,
        "deepSleepPercent": 0.18,
        "remSleepPercent": 0.24,
        "hrv": 62.0,
        "restingHeartRate": 54.0,
        "activeCalories": 430.0,
        "steps": 6320,
        "workoutMinutes": 34,
        "checkedInMorning": true,
        "sourceName": "Apple Watch"
    ])
}
