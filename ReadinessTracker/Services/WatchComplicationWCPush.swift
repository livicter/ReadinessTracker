import Foundation

/// Routes iOS → Watch snapshot delivery toward complications when WC budget allows (Honest #38).
///
/// Prefers `WCSession.transferCurrentComplicationUserInfo(_:)` while
/// `remainingComplicationUserInfoTransfers > 0`, otherwise falls back to the existing
/// `updateApplicationContext` / reachable `sendMessage` path. Soft-fail: callers guard
/// session activation; seams never throw out of this helper.
enum WatchComplicationWCPush {
    enum Route: Equatable {
        case complicationTransfer
        case applicationContextFallback
    }

    /// Chooses complication-priority transfer when budget remains; otherwise context/message.
    static func preferredRoute(remainingTransfers: Int) -> Route {
        remainingTransfers > 0 ? .complicationTransfer : .applicationContextFallback
    }

    /// Soft-fail delivery. Inject WC seams for unit tests; production wires `WCSession`.
    @discardableResult
    static func deliver(
        payload: [String: Any],
        remainingTransfers: Int,
        isReachable: Bool,
        transferComplication: ([String: Any]) -> Void,
        updateApplicationContext: ([String: Any]) throws -> Void,
        sendMessage: ([String: Any]) -> Void
    ) -> Route {
        let route = preferredRoute(remainingTransfers: remainingTransfers)
        switch route {
        case .complicationTransfer:
            transferComplication(payload)
        case .applicationContextFallback:
            try? updateApplicationContext(payload)
            if isReachable {
                sendMessage(payload)
            }
        }
        return route
    }
}
