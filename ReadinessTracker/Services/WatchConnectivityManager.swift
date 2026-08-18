import Foundation
import WatchConnectivity

/// Pushes the latest readiness/strain/sleep snapshot to the paired Apple Watch
/// and receives check-ins made on the watch.
///
/// INTEGRATION: call `WatchConnectivityManager.shared.start()` once at launch
/// (e.g. in `ReadinessTrackerApp.init()` or the App's `body` `.onAppear`), and
/// call `WatchConnectivityManager.shared.pushSnapshot()` after a health-data sync
/// completes so the watch stays fresh.
final class WatchConnectivityManager: NSObject {
    static let shared = WatchConnectivityManager()

    /// Dictionary keys shared with the watch app (watch has its own copy).
    private enum Key {
        static let date = "date"
        static let readiness = "readiness"
        static let recovery = "recovery"
        static let strain = "strain"
        static let sleepHours = "sleepHours"
        static let sleepEfficiency = "sleepEfficiency"
        static let deepSleepPercent = "deepSleepPercent"
        static let remSleepPercent = "remSleepPercent"
        static let hrv = "hrv"
        static let restingHeartRate = "restingHeartRate"
        static let activeCalories = "activeCalories"
        static let steps = "steps"
        static let workoutMinutes = "workoutMinutes"
        static let checkedInMorning = "checkedInMorning"
        static let sourceName = "sourceName"
        static let requestSnapshot = "requestSnapshot"
        static let checkIn = "checkIn"
    }

    private override init() {
        super.init()
    }

    func start() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    /// Builds a snapshot from the latest stored data and sends it to the watch
    /// (application context for background delivery + live message when reachable).
    @MainActor
    func pushSnapshot() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated else { return }
        let payload = Self.buildPayload()
        guard !payload.isEmpty else { return }
        try? session.updateApplicationContext(payload)
        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil)
        }
    }

    @MainActor
    static func buildPayload() -> [String: Any] {
        let store = DataStore.shared
        guard let data = store.latest(for: .appleWatch) ?? store.latest(for: .fitbit) else {
            return [:]
        }
        let history = store.dataForSource(data.source, days: 30)
        let breakdown = ReadinessCalculator.calculateBreakdown(from: data, history: history)
        let multiplier = MetadataStore.shared.multiplierFor(date: Date())
        let readiness = min(100, max(0, Int((Double(breakdown.totalScore) * multiplier).rounded())))
        let recovery = RecoveryCalculator.calculate(from: data, history: history)
        let strain = StrainCalculator.calculate(from: data, history: history)

        return [
            Key.date: data.date.timeIntervalSince1970,
            Key.readiness: readiness,
            Key.recovery: recovery,
            Key.strain: strain,
            Key.sleepHours: data.sleepHours,
            Key.sleepEfficiency: data.sleepEfficiency,
            Key.deepSleepPercent: data.deepSleepPercent,
            Key.remSleepPercent: data.remSleepPercent,
            Key.hrv: data.hrv,
            Key.restingHeartRate: data.restingHeartRate,
            Key.activeCalories: data.activeCalories,
            Key.steps: data.steps,
            Key.workoutMinutes: data.workoutMinutes,
            Key.checkedInMorning: MetadataStore.shared.hasCheckedInToday(.morning),
            Key.sourceName: data.source.rawValue
        ]
    }

    @MainActor
    private func handleMessage(_ message: [String: Any]) {
        if message[Key.requestSnapshot] as? Bool == true {
            pushSnapshot()
            return
        }
        if let info = message[Key.checkIn] as? [String: Any] {
            let metadata = UserMetadata(
                timeOfDay: (info["timeOfDay"] as? String) == CheckInTime.evening.rawValue ? .evening : .morning,
                subjectiveFeel: info["subjectiveFeel"] as? Int,
                alcoholConsumed: info["alcoholConsumed"] as? Bool ?? false,
                caffeineAfter2pm: info["caffeineAfter2pm"] as? Bool ?? false,
                isSick: info["isSick"] as? Bool ?? false,
                workoutToday: info["workoutToday"] as? Bool ?? false
            )
            MetadataStore.shared.save(metadata)
            pushSnapshot()
        }
    }
}

extension WatchConnectivityManager: WCSessionDelegate {
    nonisolated func session(_ session: WCSession,
                             activationDidCompleteWith activationState: WCSessionActivationState,
                             error: Error?) {
        guard activationState == .activated else { return }
        Task { @MainActor in self.pushSnapshot() }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        // Re-activate so switching paired watches keeps the channel alive.
        session.activate()
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        guard session.isReachable else { return }
        Task { @MainActor in self.pushSnapshot() }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Task { @MainActor in self.handleMessage(message) }
    }

    nonisolated func session(_ session: WCSession,
                             didReceiveMessage message: [String: Any],
                             replyHandler: @escaping ([String: Any]) -> Void) {
        Task { @MainActor in
            self.handleMessage(message)
            replyHandler(["ok": true])
        }
    }
}
