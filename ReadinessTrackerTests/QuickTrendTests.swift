import XCTest
@testable import Readiness

final class QuickTrendTests: XCTestCase {
    func testAverageAndPercentChange() {
        let history = (1...14).map { i in
            DailyHealthData(
                date: Date().addingTimeInterval(TimeInterval(i) * 86400),
                source: .appleWatch,
                activeCalories: Double(i * 100)
            )
        }

        let trend = QuickTrendCard.computeTrend(metric: .activeCalories, history: history, window: 7)

        XCTAssertEqual(trend.average, 1100, accuracy: 0.1)
        XCTAssertEqual(trend.percentChange, 175, accuracy: 0.1)
    }

    func testIncreasingValuesYieldStrongUp() {
        let history = (1...7).map { i in
            DailyHealthData(
                date: Date().addingTimeInterval(TimeInterval(i) * 86400),
                source: .appleWatch,
                activeCalories: Double(i * 100)
            )
        }

        let trend = QuickTrendCard.computeTrend(metric: .activeCalories, history: history, window: 7)

        XCTAssertEqual(trend.strength, .strongUp)
    }

    func testImprovingRestingHRYieldsStrongUp() {
        let history = (0..<7).map { i in
            DailyHealthData(
                date: Date().addingTimeInterval(TimeInterval(i) * 86400),
                source: .appleWatch,
                restingHeartRate: Double(80 - i * 5)
            )
        }

        let trend = QuickTrendCard.computeTrend(metric: .restingHR, history: history, window: 7)

        XCTAssertEqual(trend.strength, .strongUp)
    }
}
