import XCTest
@testable import Readiness

/// Honest #42: App Group snapshot builder shared by Provider getSnapshot/getTimeline.
final class HomeWidgetAppGroupEntryTests: XCTestCase {
    func testLoadReturnsNilWhenSuiteEmpty() {
        let suiteName = "group.com.readinesstracker.tests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Failed to create test UserDefaults suite")
            return
        }
        defer { defaults.removePersistentDomain(forName: suiteName) }

        XCTAssertEqual(HomeWidgetAppGroupEntry.suiteName, "group.com.readinesstracker")
        XCTAssertNil(HomeWidgetAppGroupEntry.load(from: defaults))
        XCTAssertNil(HomeWidgetAppGroupEntry.load(from: nil))
    }

    func testLoadReadsScoresAndLastUpdate() {
        let suiteName = "group.com.readinesstracker.tests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Failed to create test UserDefaults suite")
            return
        }
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let stamp = Date(timeIntervalSince1970: 1_725_000_000)
        defaults.set(79, forKey: "readinessScore")
        defaults.set(82, forKey: "gymScore")
        defaults.set(75, forKey: "workScore")
        defaults.set(80, forKey: "sleepScore")
        defaults.set(45, forKey: "hrv")
        defaults.set(58, forKey: "rhr")
        defaults.set(7.5, forKey: "sleepHours")
        defaults.set(stamp, forKey: "lastUpdate")

        guard let snap = HomeWidgetAppGroupEntry.load(from: defaults) else {
            XCTFail("Expected snapshot from populated suite")
            return
        }

        XCTAssertEqual(snap.readinessScore, 79)
        XCTAssertEqual(snap.gymScore, 82)
        XCTAssertEqual(snap.workScore, 75)
        XCTAssertEqual(snap.sleepScore, 80)
        XCTAssertEqual(snap.hrv, 45)
        XCTAssertEqual(snap.rhr, 58)
        XCTAssertEqual(snap.sleepHours, 7.5, accuracy: 0.001)
        XCTAssertEqual(snap.lastUpdate, stamp)
    }
}
