import XCTest
@testable import Readiness

final class HRVCalculatorTests: XCTestCase {
    func testRMSSDFromKnownRRIntervals() {
        // Successive differences: 10, -20, 10
        // Squared: 100, 400, 100 -> mean 200 -> sqrt 200 ≈ 14.142
        let rr: [Double] = [1000, 1010, 990, 1000]
        let result = HRVCalculator.rmssd(from: rr)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!, 14.142, accuracy: 0.001)
    }

    func testRMSSDLessThanTwoIntervalsReturnsNil() {
        XCTAssertNil(HRVCalculator.rmssd(from: [1000]))
        XCTAssertNil(HRVCalculator.rmssd(from: []))
    }

    func testSDNNFromKnownRRIntervals() {
        let rr: [Double] = [1000, 1010, 990, 1000]
        // mean = 1000, variance = (0 + 100 + 100 + 0)/4 = 50, sd = sqrt(50) ≈ 7.071
        let result = HRVCalculator.sdnn(from: rr)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!, 7.071, accuracy: 0.001)
    }

    func testSDNNLessThanTwoIntervalsReturnsNil() {
        XCTAssertNil(HRVCalculator.sdnn(from: [1000]))
        XCTAssertNil(HRVCalculator.sdnn(from: []))
    }
}
