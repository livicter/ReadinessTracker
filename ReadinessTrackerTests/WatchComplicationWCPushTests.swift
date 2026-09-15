import XCTest
@testable import Readiness

/// Honest #38/#39: seam proves complication WC transfer prefers budget + glance-change throttle.
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

    func testPreferredRouteSkipsTransferWhenGlanceUnchangedEvenWithBudget() {
        XCTAssertEqual(
            WatchComplicationWCPush.preferredRoute(
                remainingTransfers: 50,
                glanceFieldsChanged: false
            ),
            .applicationContextFallback
        )
    }

    func testPreferredRouteTransfersWhenGlanceChangedAndBudgetRemains() {
        XCTAssertEqual(
            WatchComplicationWCPush.preferredRoute(
                remainingTransfers: 1,
                glanceFieldsChanged: true
            ),
            .complicationTransfer
        )
    }

    func testGlanceFingerprintIgnoresNonGlanceNoise() {
        let a: [String: Any] = [
            "readiness": 80,
            "gymScore": 70,
            "workScore": 60,
            "sleepScore": 90,
            "recovery": 75,
            "strain": 8.5,
            "steps": 1000
        ]
        let b: [String: Any] = [
            "readiness": 80,
            "gymScore": 70,
            "workScore": 60,
            "sleepScore": 90,
            "recovery": 75,
            "strain": 8.5,
            "steps": 9999,
            "hrv": 42
        ]
        XCTAssertEqual(
            WatchComplicationWCPush.GlanceFingerprint.make(from: a),
            WatchComplicationWCPush.GlanceFingerprint.make(from: b)
        )
        XCTAssertFalse(
            WatchComplicationWCPush.glanceFieldsChanged(
                payload: b,
                lastFingerprint: WatchComplicationWCPush.GlanceFingerprint.make(from: a).token
            )
        )
    }

    func testGlanceFieldsChangedWhenRingOrRecoveryStrainDiffers() {
        let base: [String: Any] = [
            "readiness": 80,
            "gymScore": 70,
            "workScore": 60,
            "sleepScore": 90,
            "recovery": 75,
            "strain": 8.5
        ]
        let last = WatchComplicationWCPush.GlanceFingerprint.make(from: base).token
        XCTAssertTrue(
            WatchComplicationWCPush.glanceFieldsChanged(payload: base, lastFingerprint: nil),
            "Nil last fingerprint must treat as changed (first send)"
        )
        XCTAssertFalse(
            WatchComplicationWCPush.glanceFieldsChanged(payload: base, lastFingerprint: last)
        )

        var readinessChanged = base
        readinessChanged["readiness"] = 81
        XCTAssertTrue(
            WatchComplicationWCPush.glanceFieldsChanged(
                payload: readinessChanged,
                lastFingerprint: last
            )
        )

        var gymChanged = base
        gymChanged["gymScore"] = 71
        XCTAssertTrue(
            WatchComplicationWCPush.glanceFieldsChanged(payload: gymChanged, lastFingerprint: last)
        )

        var strainChanged = base
        strainChanged["strain"] = 9.0
        XCTAssertTrue(
            WatchComplicationWCPush.glanceFieldsChanged(
                payload: strainChanged,
                lastFingerprint: last
            )
        )
    }

    func testDeliverUsesComplicationTransferSeamWhenBudgetRemains() {
        var transferred: [[String: Any]] = []
        var contexts: [[String: Any]] = []
        var messages: [[String: Any]] = []
        var persisted: [String] = []
        let payload: [String: Any] = [
            "readiness": 81,
            "gymScore": 80,
            "workScore": 70,
            "sleepScore": 75,
            "recovery": 82,
            "strain": 7.2
        ]

        let route = WatchComplicationWCPush.deliver(
            payload: payload,
            remainingTransfers: 3,
            isReachable: true,
            lastFingerprint: nil,
            persistFingerprint: { persisted.append($0) },
            transferComplication: { transferred.append($0) },
            updateApplicationContext: { contexts.append($0) },
            sendMessage: { messages.append($0) }
        )

        XCTAssertEqual(route, .complicationTransfer)
        XCTAssertEqual(transferred.count, 1)
        XCTAssertEqual(transferred.first?["readiness"] as? Int, 81)
        XCTAssertTrue(contexts.isEmpty, "Must not fall back to context when budget remains")
        XCTAssertTrue(messages.isEmpty, "Must not send live message when complication transfer is used")
        XCTAssertEqual(persisted.count, 1)
        XCTAssertEqual(
            persisted.first,
            WatchComplicationWCPush.GlanceFingerprint.make(from: payload).token
        )
    }

    func testDeliverSkipsTransferWhenGlanceUnchangedButKeepsContextFallback() {
        var transferred: [[String: Any]] = []
        var contexts: [[String: Any]] = []
        var messages: [[String: Any]] = []
        var persisted: [String] = []
        let payload: [String: Any] = [
            "readiness": 81,
            "gymScore": 80,
            "workScore": 70,
            "sleepScore": 75,
            "recovery": 82,
            "strain": 7.2,
            "steps": 1234
        ]
        let last = WatchComplicationWCPush.GlanceFingerprint.make(from: payload).token

        let route = WatchComplicationWCPush.deliver(
            payload: payload,
            remainingTransfers: 50,
            isReachable: true,
            lastFingerprint: last,
            persistFingerprint: { persisted.append($0) },
            transferComplication: { transferred.append($0) },
            updateApplicationContext: { contexts.append($0) },
            sendMessage: { messages.append($0) }
        )

        XCTAssertEqual(route, .applicationContextFallback)
        XCTAssertTrue(transferred.isEmpty, "Unchanged glance must not spend a complication transfer")
        XCTAssertEqual(contexts.count, 1, "Context fallback must still run")
        XCTAssertEqual(messages.count, 1, "Reachable message fallback must still run")
        XCTAssertEqual(persisted.first, last)
    }

    func testDeliverTransfersAgainWhenGlanceChanges() {
        var transferred = 0
        let first: [String: Any] = [
            "readiness": 70, "gymScore": 70, "workScore": 70, "sleepScore": 70,
            "recovery": 70, "strain": 5.0
        ]
        let second: [String: Any] = [
            "readiness": 71, "gymScore": 70, "workScore": 70, "sleepScore": 70,
            "recovery": 70, "strain": 5.0
        ]
        let last = WatchComplicationWCPush.GlanceFingerprint.make(from: first).token

        let route = WatchComplicationWCPush.deliver(
            payload: second,
            remainingTransfers: 2,
            isReachable: false,
            lastFingerprint: last,
            persistFingerprint: { _ in },
            transferComplication: { _ in transferred += 1 },
            updateApplicationContext: { _ in XCTFail("Should not fall back when changed + budget") },
            sendMessage: { _ in XCTFail("Should not message when complication transfer used") }
        )

        XCTAssertEqual(route, .complicationTransfer)
        XCTAssertEqual(transferred, 1)
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

    func testFingerprintStoreRoundTripViaUserDefaults() {
        let suiteName = "WatchComplicationWCPushTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        XCTAssertNil(WatchComplicationWCPush.FingerprintStore.load(defaults: defaults))
        WatchComplicationWCPush.FingerprintStore.save("abc|def", defaults: defaults)
        XCTAssertEqual(
            WatchComplicationWCPush.FingerprintStore.load(defaults: defaults),
            "abc|def"
        )
    }
}
