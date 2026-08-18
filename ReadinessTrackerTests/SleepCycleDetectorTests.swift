import XCTest
@testable import Readiness

final class SleepCycleDetectorTests: XCTestCase {

    private let base = Date(timeIntervalSince1970: 1_700_000_000)

    private func iv(_ stage: SleepStage, _ startMin: Double, _ endMin: Double) -> SleepStageInterval {
        SleepStageInterval(
            stage: stage,
            startDate: base.addingTimeInterval(startMin * 60),
            endDate: base.addingTimeInterval(endMin * 60)
        )
    }

    func testEmptyInputReturnsNoCycles() {
        XCTAssertTrue(SleepCycleDetector.detectCycles(in: []).isEmpty)
    }

    func testSingleContinuousBlockIsOneCycle() {
        let intervals = [iv(.light, 0, 30), iv(.deep, 30, 60), iv(.rem, 60, 90)]
        let cycles = SleepCycleDetector.detectCycles(in: intervals)
        XCTAssertEqual(cycles.count, 1)
        XCTAssertEqual(cycles[0].durationMinutes, 90, accuracy: 0.001)
        XCTAssertEqual(cycles[0].deepMinutes, 30, accuracy: 0.001)
        XCTAssertEqual(cycles[0].remMinutes, 30, accuracy: 0.001)
        XCTAssertEqual(cycles[0].lightMinutes, 30, accuracy: 0.001)
    }

    func testShortAwakeGapDoesNotSplitCycle() {
        let intervals = [iv(.light, 0, 40), iv(.awake, 40, 50), iv(.rem, 50, 90)]
        let cycles = SleepCycleDetector.detectCycles(in: intervals)
        XCTAssertEqual(cycles.count, 1)
    }

    func testLongAwakeGapSplitsCycles() {
        let intervals = [
            iv(.light, 0, 45), iv(.deep, 45, 90),
            iv(.awake, 90, 110),                    // 20 min > 15 min threshold
            iv(.light, 110, 150), iv(.rem, 150, 180)
        ]
        let cycles = SleepCycleDetector.detectCycles(in: intervals)
        XCTAssertEqual(cycles.count, 2)
        XCTAssertEqual(cycles[0].startDate, base)
        XCTAssertEqual(cycles[0].endDate, base.addingTimeInterval(90 * 60))
        XCTAssertEqual(cycles[1].startDate, base.addingTimeInterval(110 * 60))
    }

    func testAwakeAtExactlyThresholdDoesNotSplit() {
        let intervals = [iv(.light, 0, 30), iv(.awake, 30, 45), iv(.deep, 45, 75)]
        XCTAssertEqual(SleepCycleDetector.detectCycles(in: intervals).count, 1)
    }

    func testUnsortedInputIsHandled() {
        let intervals = [iv(.rem, 60, 90), iv(.light, 0, 30), iv(.deep, 30, 60)]
        let cycles = SleepCycleDetector.detectCycles(in: intervals)
        XCTAssertEqual(cycles.count, 1)
        XCTAssertEqual(cycles[0].startDate, base)
    }

    func testAwakePeriodsExtraction() {
        let intervals = [iv(.light, 0, 30), iv(.awake, 30, 45), iv(.deep, 45, 75), iv(.awake, 75, 80)]
        let awake = SleepCycleDetector.awakePeriods(from: intervals)
        XCTAssertEqual(awake.count, 2)
        XCTAssertEqual(awake[0].start, base.addingTimeInterval(30 * 60))
        XCTAssertEqual(awake[1].end, base.addingTimeInterval(80 * 60))
    }

    func testOnlyAwakeInputReturnsNoCycles() {
        let intervals = [iv(.awake, 0, 60)]
        XCTAssertTrue(SleepCycleDetector.detectCycles(in: intervals).isEmpty)
    }
}
