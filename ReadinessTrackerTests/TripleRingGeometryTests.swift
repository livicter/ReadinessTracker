import XCTest
import CoreGraphics
@testable import Readiness

final class TripleRingGeometryTests: XCTestCase {
    func testHeroLayoutDiametersMatchActivityPacking() {
        let size: CGFloat = 180
        let layout = TripleRingGeometry.layout(size: size, minimumLineWidth: 12, gap: 2)
        XCTAssertEqual(layout.lineWidth, 18, accuracy: 0.001) // max(12, 180/10)
        XCTAssertEqual(layout.gap, 2, accuracy: 0.001)
        XCTAssertEqual(layout.outerSize, size, accuracy: 0.001)
        let step = layout.lineWidth + layout.gap
        XCTAssertEqual(layout.middleSize, size - 2 * step, accuracy: 0.001)
        XCTAssertEqual(layout.innerSize, size - 4 * step, accuracy: 0.001)
        XCTAssertEqual(layout.holeDiameter, size - 4 * step - layout.lineWidth, accuracy: 0.001)
        XCTAssertGreaterThan(layout.innerSize, layout.lineWidth)
        XCTAssertGreaterThan(layout.holeDiameter, 0)
    }

    func testWidgetCompactLayoutUsesLowerStrokeFloor() {
        let size: CGFloat = 96
        let layout = TripleRingGeometry.layout(size: size, minimumLineWidth: 5, gap: 2)
        XCTAssertEqual(layout.lineWidth, max(5, size / 10), accuracy: 0.001)
        XCTAssertEqual(layout.outerSize, 96, accuracy: 0.001)
        XCTAssertGreaterThan(layout.middleSize, layout.innerSize)
        XCTAssertGreaterThan(layout.innerSize, 0)
        XCTAssertGreaterThan(layout.holeDiameter, 20)
    }

    func testOverallScoreIsMeanRoundedTowardZero() {
        XCTAssertEqual(TripleRingGeometry.overallScore(gym: 82, work: 75, sleep: 80), 79)
        XCTAssertEqual(TripleRingGeometry.overallScore(gym: 100, work: 100, sleep: 100), 100)
        XCTAssertEqual(TripleRingGeometry.overallScore(gym: 0, work: 0, sleep: 0), 0)
    }

    func testProgressClamps() {
        XCTAssertEqual(TripleRingGeometry.progress(score: 50), 0.5, accuracy: 0.0001)
        XCTAssertEqual(TripleRingGeometry.progress(score: -10), 0, accuracy: 0.0001)
        XCTAssertEqual(TripleRingGeometry.progress(score: 150), 1, accuracy: 0.0001)
    }
}
