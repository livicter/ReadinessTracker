import Foundation

/// Routes iOS → Watch snapshot delivery toward complications when WC budget allows (Honest #38),
/// and throttles complication-priority transfers when glance scores are unchanged (Honest #39).
///
/// Prefers `WCSession.transferCurrentComplicationUserInfo(_:)` while
/// `remainingComplicationUserInfoTransfers > 0` **and** glance-relevant fields changed;
/// otherwise falls back to the existing `updateApplicationContext` / reachable `sendMessage`
/// path. Soft-fail: callers guard session activation; seams never throw out of this helper.
///
/// App Group writes stay outside this helper (`WatchConnectivityManager.pushSnapshot` /
/// `WatchSnapshotAppGroupStore`) so they always run regardless of WC route.
enum WatchComplicationWCPush {
    enum Route: Equatable {
        case complicationTransfer
        case applicationContextFallback
    }

    /// Glance-relevant payload keys for complication-priority transfer throttle.
    /// Rings use readiness/gym/work/sleep; recovery/strain ride the same snapshot.
    static let glanceFingerprintKeys: [String] = [
        "readiness", "gymScore", "workScore", "sleepScore", "recovery", "strain"
    ]

    static let fingerprintDefaultsKey = "WatchComplicationWCPush.lastGlanceFingerprint"

    /// Stable fingerprint of glance-relevant fields for transfer throttling.
    struct GlanceFingerprint: Equatable {
        let token: String

        static func make(from payload: [String: Any]) -> GlanceFingerprint {
            let parts = glanceFingerprintKeys.map { key -> String in
                "\(key)=\(stringify(payload[key]))"
            }
            return GlanceFingerprint(token: parts.joined(separator: "|"))
        }

        private static func stringify(_ value: Any?) -> String {
            guard let value else { return "" }
            switch value {
            case let i as Int:
                return String(i)
            case let d as Double:
                if d.rounded() == d, d >= Double(Int.min), d <= Double(Int.max) {
                    return String(Int(d))
                }
                return String(format: "%.4f", d)
            case let f as Float:
                return stringify(Double(f))
            case let n as NSNumber:
                // Bool bridges to NSNumber; treat 0/1 ints preferentially via intValue when whole.
                if CFGetTypeID(n) == CFBooleanGetTypeID() {
                    return n.boolValue ? "1" : "0"
                }
                let d = n.doubleValue
                if d.rounded() == d, d >= Double(Int.min), d <= Double(Int.max) {
                    return String(Int(d))
                }
                return String(format: "%.4f", d)
            case let s as String:
                return s
            default:
                return String(describing: value)
            }
        }
    }

    /// UserDefaults-backed last-sent glance fingerprint (injectable for tests).
    enum FingerprintStore {
        static func load(defaults: UserDefaults = .standard) -> String? {
            defaults.string(forKey: fingerprintDefaultsKey)
        }

        static func save(_ token: String, defaults: UserDefaults = .standard) {
            defaults.set(token, forKey: fingerprintDefaultsKey)
        }
    }

    /// `true` when there is no prior fingerprint or glance fields differ from last-sent.
    static func glanceFieldsChanged(payload: [String: Any], lastFingerprint: String?) -> Bool {
        let current = GlanceFingerprint.make(from: payload).token
        guard let lastFingerprint else { return true }
        return current != lastFingerprint
    }

    /// Chooses complication-priority transfer when budget remains **and** glance fields changed;
    /// otherwise context/message fallback (Honest #39 throttle).
    static func preferredRoute(
        remainingTransfers: Int,
        glanceFieldsChanged: Bool = true
    ) -> Route {
        remainingTransfers > 0 && glanceFieldsChanged
            ? .complicationTransfer
            : .applicationContextFallback
    }

    /// Soft-fail delivery. Inject WC + fingerprint seams for unit tests; production wires `WCSession`.
    /// Always attempts context/message when skipping or falling back from complication transfer.
    /// Persists the glance fingerprint after a delivery attempt so unchanged scores skip transfers.
    @discardableResult
    static func deliver(
        payload: [String: Any],
        remainingTransfers: Int,
        isReachable: Bool,
        lastFingerprint: String? = nil,
        persistFingerprint: ((String) -> Void)? = nil,
        transferComplication: ([String: Any]) -> Void,
        updateApplicationContext: ([String: Any]) throws -> Void,
        sendMessage: ([String: Any]) -> Void
    ) -> Route {
        let fingerprint = GlanceFingerprint.make(from: payload).token
        let changed = glanceFieldsChanged(payload: payload, lastFingerprint: lastFingerprint)
        let route = preferredRoute(
            remainingTransfers: remainingTransfers,
            glanceFieldsChanged: changed
        )
        switch route {
        case .complicationTransfer:
            transferComplication(payload)
        case .applicationContextFallback:
            try? updateApplicationContext(payload)
            if isReachable {
                sendMessage(payload)
            }
        }
        persistFingerprint?(fingerprint)
        return route
    }
}
