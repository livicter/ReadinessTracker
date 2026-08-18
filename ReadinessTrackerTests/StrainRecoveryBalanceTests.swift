import XCTest
@testable import Readiness

final class StrainRecoveryBalanceTests: XCTestCase {
    func testBalanced() {
        let balance = StrainRecoveryBalance.compute(recovery: 80, strain: 10.5)
        XCTAssertEqual(balance.score, 80)
        XCTAssertEqual(balance.status, "Balanced")
    }

    func testModerateLoad() {
        let balance = StrainRecoveryBalance.compute(recovery: 60, strain: 10.5)
        XCTAssertEqual(balance.score, 60)
        XCTAssertEqual(balance.status, "Moderate Load")
    }

    func testOverreachingRisk() {
        let balance = StrainRecoveryBalance.compute(recovery: 55, strain: 14.0)
        XCTAssertEqual(balance.score, 38)
        XCTAssertEqual(balance.status, "Overreaching Risk")
    }

    func testRestNeeded() {
        let balance = StrainRecoveryBalance.compute(recovery: 40, strain: 18.0)
        XCTAssertEqual(balance.score, 4)
        XCTAssertEqual(balance.status, "Rest Needed")
    }

    func testClampsToZeroAndHundred() {
        let low = StrainRecoveryBalance.compute(recovery: 0, strain: 21.0)
        XCTAssertEqual(low.score, 0)
        XCTAssertEqual(low.status, "Rest Needed")

        let high = StrainRecoveryBalance.compute(recovery: 100, strain: 0.0)
        XCTAssertEqual(high.score, 100)
        XCTAssertEqual(high.status, "Balanced")
    }
}
