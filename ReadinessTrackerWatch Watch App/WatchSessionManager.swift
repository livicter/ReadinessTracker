import Combine
import Foundation
import WatchConnectivity

/// Receives readiness snapshots from the iPhone and sends watch check-ins back.
/// Persists the last snapshot to UserDefaults so the app opens with data.
final class WatchSessionManager: NSObject, ObservableObject {
    static let shared = WatchSessionManager()

    @Published private(set) var snapshot: WatchSnapshot?
    @Published private(set) var isPhoneReachable = false

    private let defaultsKey = "lastWatchSnapshot"
    private let appGroupID = "group.com.readinesstracker"

    private override init() {
        super.init()
        if let dict = UserDefaults.standard.dictionary(forKey: defaultsKey)
            ?? UserDefaults(suiteName: appGroupID)?.dictionary(forKey: defaultsKey) {
            snapshot = WatchSnapshot(dictionary: dict)
        }
    }

    /// Persist for the Watch App and (when App Group is provisioned) the complication extension.
    /// After a successful mirror write, soft-fail reload Watch Widgets timelines (Honest #37).
    private func persistSnapshotDictionary(_ dict: [String: Any]) {
        UserDefaults.standard.set(dict, forKey: defaultsKey)
        UserDefaults(suiteName: appGroupID)?.set(dict, forKey: defaultsKey)
        WatchComplicationTimelineReloader.reloadAfterSnapshotWrite()
    }

    func start() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    /// Ask the phone for a fresh snapshot (no-op when unreachable; the phone
    /// also pushes on activation and after each sync).
    func requestSnapshot() {
        let session = WCSession.default
        guard session.activationState == .activated, session.isReachable else { return }
        session.sendMessage(["requestSnapshot": true], replyHandler: nil)
    }

    func sendCheckIn(timeOfDay: String, subjectiveFeel: Int?, alcoholConsumed: Bool,
                     caffeineAfter2pm: Bool, isSick: Bool, workoutToday: Bool,
                     completion: @escaping (Bool) -> Void) {
        let session = WCSession.default
        guard session.activationState == .activated, session.isReachable else {
            completion(false)
            return
        }
        var info: [String: Any] = [
            "timeOfDay": timeOfDay,
            "alcoholConsumed": alcoholConsumed,
            "caffeineAfter2pm": caffeineAfter2pm,
            "isSick": isSick,
            "workoutToday": workoutToday
        ]
        if let subjectiveFeel { info["subjectiveFeel"] = subjectiveFeel }
        session.sendMessage(["checkIn": info], replyHandler: { _ in
            Task { @MainActor in completion(true) }
        }, errorHandler: { _ in
            Task { @MainActor in completion(false) }
        })
    }

    private func apply(_ dictionary: [String: Any]) {
        guard dictionary["readiness"] != nil else { return }
        snapshot = WatchSnapshot(dictionary: dictionary)
        persistSnapshotDictionary(dictionary)
    }
}

extension WatchSessionManager: WCSessionDelegate {
    nonisolated func session(_ session: WCSession,
                             activationDidCompleteWith activationState: WCSessionActivationState,
                             error: Error?) {
        Task { @MainActor in
            self.isPhoneReachable = session.isReachable
            if activationState == .activated {
                self.requestSnapshot()
            }
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        let reachable = session.isReachable
        Task { @MainActor in
            self.isPhoneReachable = reachable
            if reachable { self.requestSnapshot() }
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext context: [String: Any]) {
        Task { @MainActor in self.apply(context) }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Task { @MainActor in self.apply(message) }
    }

    /// Complication-priority transfers (`transferCurrentComplicationUserInfo`) and
    /// queued `transferUserInfo` arrive here (Honest #38). Same persist + timeline reload
    /// path as application-context / message snapshots.
    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        Task { @MainActor in self.apply(userInfo) }
    }
}
