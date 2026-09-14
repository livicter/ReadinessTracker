import XCTest
import CoreGraphics
@testable import Readiness

final class StrainRecoveryDualArcGeometryTests: XCTestCase {
    func testTodayLayoutMatchesWHOOPReference() {
        let layout = StrainRecoveryDualArcGeometry.layout(size: 180, minimumOuterWidth: 20, minimumInnerWidth: 14)
        XCTAssertEqual(layout.size, 180, accuracy: 0.001)
        XCTAssertEqual(layout.outerWidth, 20, accuracy: 0.001)
        XCTAssertEqual(layout.innerWidth, 14, accuracy: 0.001)
        XCTAssertEqual(layout.ringInset, 20, accuracy: 0.001)
        XCTAssertGreaterThan(layout.holeDiameter, 100)
        XCTAssertGreaterThan(layout.centerScoreFontSize, 16)
    }

    func testWatchCompactLayoutScalesDown() {
        let layout = StrainRecoveryDualArcGeometry.layout(size: 110, minimumOuterWidth: 8, minimumInnerWidth: 6)
        XCTAssertEqual(layout.size, 110, accuracy: 0.001)
        XCTAssertGreaterThanOrEqual(layout.outerWidth, 8)
        XCTAssertGreaterThanOrEqual(layout.innerWidth, 6)
        XCTAssertEqual(layout.ringInset, layout.outerWidth, accuracy: 0.001)
        XCTAssertGreaterThan(layout.holeDiameter, 40)
        XCTAssertLessThan(layout.centerScoreFontSize, 28)
    }

    func testFractionsClamp() {
        XCTAssertEqual(StrainRecoveryDualArcGeometry.strainFraction(10.5), 0.5, accuracy: 0.0001)
        XCTAssertEqual(StrainRecoveryDualArcGeometry.strainFraction(-1), 0, accuracy: 0.0001)
        XCTAssertEqual(StrainRecoveryDualArcGeometry.strainFraction(42), 1, accuracy: 0.0001)
        XCTAssertEqual(StrainRecoveryDualArcGeometry.recoveryFraction(78), 0.78, accuracy: 0.0001)
        XCTAssertEqual(StrainRecoveryDualArcGeometry.recoveryFraction(-5), 0, accuracy: 0.0001)
        XCTAssertEqual(StrainRecoveryDualArcGeometry.recoveryFraction(150), 1, accuracy: 0.0001)
    }
}
