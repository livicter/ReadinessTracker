import XCTest
@testable import Readiness

final class BaselineManagerTests: XCTestCase {
    func testHRVBaselineFiltersByRMSSDFlag() {
        let sdnnHistory = (0..<5).map { _ in
            DailyHealthData(date: Date(), source: .appleWatch, hrv: 50, hrvIsRMSSD: false)
        }
        let rmssdHistory = (0..<5).map { _ in
            DailyHealthData(date: Date(), source: .appleWatch, hrv: 30, hrvIsRMSSD: true)
        }
        let history = sdnnHistory + rmssdHistory

        let rmssdBaseline = BaselineManager.hrvBaseline(from: history, matchesRMSSD: true)
        let sdnnBaseline = BaselineManager.hrvBaseline(from: history, matchesRMSSD: false)

        XCTAssertEqual(rmssdBaseline, 30, accuracy: 0.1)
        XCTAssertEqual(sdnnBaseline, 50, accuracy: 0.1)
    }

    func testHRVBaselineFallsBackWhenFewMatchingPoints() {
        let sdnnHistory = (0..<5).map { _ in
            DailyHealthData(date: Date(), source: .appleWatch, hrv: 50, hrvIsRMSSD: false)
        }
        let rmssdHistory = (0..<2).map { _ in
            DailyHealthData(date: Date(), source: .appleWatch, hrv: 30, hrvIsRMSSD: true)
        }
        let history = sdnnHistory + rmssdHistory

        let baseline = BaselineManager.hrvBaseline(from: history, matchesRMSSD: true)
        // Only 2 RMSSD points, so fallback to all history: (5*50 + 2*30) / 7 ≈ 44.3
        XCTAssertEqual(baseline, 44.3, accuracy: 0.1)
    }
}
