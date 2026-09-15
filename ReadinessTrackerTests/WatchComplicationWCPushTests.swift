import XCTest
@testable import Readiness

/// Honest #38: seam proves complication WC transfer is preferred when budget remains.
final class WatchComplicationWCPushTests: XCTestCase {
    func testPreferredRouteUsesComplicationTransferWhenBudgetRemains() {
        XCTAssertEqual(
            WatchComplicationWCPush.preferredRoute(remainingTransfers: 1),
            .complicationTransfer
        )
        XCTAssertEqual(
            WatchComplicationWCPush.preferredRoute(remainingTransfers: 50),
            .complicationTransfer
        )
    }

    func testPreferredRouteFallsBackWhenNoTransfersRemain() {
        XCTAssertEqual(
            WatchComplicationWCPush.preferredRoute(remainingTransfers: 0),
            .applicationContextFallback
        )
        XCTAssertEqual(
            WatchComplicationWCPush.preferredRoute(remainingTransfers: -1),
            .applicationContextFallback
        )
    }

    func testDeliverUsesComplicationTransferSeamWhenBudgetRemains() {
        var transferred: [[String: Any]] = []
        var contexts: [[String: Any]] = []
        var messages: [[String: Any]] = []
        let payload: [String: Any] = ["readiness": 81, "gymScore": 80]

        let route = WatchComplicationWCPush.deliver(
            payload: payload,
            remainingTransfers: 3,
            isReachable: true,
            transferComplication: { transferred.append($0) },
            updateApplicationContext: { contexts.append($0) },
            sendMessage: { messages.append($0) }
        )

        XCTAssertEqual(route, .complicationTransfer)
        XCTAssertEqual(transferred.count, 1)
        XCTAssertEqual(transferred.first?["readiness"] as? Int, 81)
        XCTAssertTrue(contexts.isEmpty, "Must not fall back to context when budget remains")
        XCTAssertTrue(messages.isEmpty, "Must not send live message when complication transfer is used")
    }

    func testDeliverFallsBackToContextAndReachableMessage() {
        var transferred: [[String: Any]] = []
        var contexts: [[String: Any]] = []
        var messages: [[String: Any]] = []
        let payload: [String: Any] = ["readiness": 70]

        let route = WatchComplicationWCPush.deliver(
            payload: payload,
            remainingTransfers: 0,
            isReachable: true,
            transferComplication: { transferred.append($0) },
            updateApplicationContext: { contexts.append($0) },
            sendMessage: { messages.append($0) }
        )

        XCTAssertEqual(route, .applicationContextFallback)
        XCTAssertTrue(transferred.isEmpty)
        XCTAssertEqual(contexts.count, 1)
        XCTAssertEqual(messages.count, 1)
        XCTAssertEqual(contexts.first?["readiness"] as? Int, 70)
    }

    func testDeliverFallbackSkipsMessageWhenUnreachable() {
        var messages: [[String: Any]] = []
        var contexts = 0

        _ = WatchComplicationWCPush.deliver(
            payload: ["readiness": 60],
            remainingTransfers: 0,
            isReachable: false,
            transferComplication: { _ in XCTFail("Should not transfer") },
            updateApplicationContext: { _ in contexts += 1 },
            sendMessage: { messages.append($0) }
        )

        XCTAssertEqual(contexts, 1)
        XCTAssertTrue(messages.isEmpty)
    }

    func testDeliverSoftFailsWhenContextThrows() {
        var messages = 0
        let route = WatchComplicationWCPush.deliver(
            payload: ["readiness": 55],
            remainingTransfers: 0,
            isReachable: true,
            transferComplication: { _ in },
            updateApplicationContext: { _ in throw NSError(domain: "test", code: 1) },
            sendMessage: { _ in messages += 1 }
        )
        XCTAssertEqual(route, .applicationContextFallback)
        XCTAssertEqual(messages, 1, "Reachable message still attempted after soft-fail context")
    }
}
