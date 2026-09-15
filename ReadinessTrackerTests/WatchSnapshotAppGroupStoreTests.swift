import XCTest
@testable import Readiness

/// Honest #36: App Group writer encode/write/read round-trip for `lastWatchSnapshot`.
final class WatchSnapshotAppGroupStoreTests: XCTestCase {
    func testWriteReadRoundTripsSnapshotPayload() {
        let suiteName = "group.com.readinesstracker.tests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Failed to create test UserDefaults suite")
            return
        }
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let payload: [String: Any] = [
            "date": 1_725_000_000.0,
            "readiness": 79,
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
            "sourceName": "Apple Watch",
            "gymScore": 82,
            "workScore": 75,
            "sleepScore": 80
        ]

        WatchSnapshotAppGroupStore.write(payload, defaults: defaults)
        guard let loaded = WatchSnapshotAppGroupStore.read(defaults: defaults) else {
            XCTFail("Expected snapshot dictionary after write")
            return
        }

        XCTAssertEqual(WatchSnapshotAppGroupStore.appGroupID, "group.com.readinesstracker")
        XCTAssertEqual(WatchSnapshotAppGroupStore.snapshotKey, "lastWatchSnapshot")
        XCTAssertEqual(loaded["readiness"] as? Int, 79)
        XCTAssertEqual(loaded["gymScore"] as? Int, 82)
        XCTAssertEqual(loaded["workScore"] as? Int, 75)
        XCTAssertEqual(loaded["sleepScore"] as? Int, 80)
        XCTAssertEqual(loaded["hrv"] as? Double, 62.0)
        XCTAssertEqual(loaded["sourceName"] as? String, "Apple Watch")
        XCTAssertEqual(loaded["checkedInMorning"] as? Bool, true)
        XCTAssertEqual(loaded["date"] as? Double, 1_725_000_000.0)
    }

    func testWriteSkipsEmptyPayload() {
        let suiteName = "group.com.readinesstracker.tests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Failed to create test UserDefaults suite")
            return
        }
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        WatchSnapshotAppGroupStore.write([:], defaults: defaults)
        XCTAssertNil(WatchSnapshotAppGroupStore.read(defaults: defaults))
    }
}
