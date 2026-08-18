import XCTest
@testable import Readiness

@MainActor
final class AIRecommendationsTests: XCTestCase {
    private let engine = AIRecommendationEngine.shared

    override func setUp() {
        super.setUp()
        DataStore.shared.history = []
        MetadataStore.shared.entries = []
    }

    override func tearDown() {
        DataStore.shared.history = []
        MetadataStore.shared.entries = []
        super.tearDown()
    }

    func testHighStrainAndLowRecoveryTriggersCriticalRest() {
        let day = DailyHealthData(
            date: Date(), source: .appleWatch,
            hrv: 20, restingHeartRate: 75,
            activeCalories: 6000, workoutMinutes: 180
        )
        DataStore.shared.history = [day]

        let recs = engine.generateRecommendations(for: .appleWatch)
        XCTAssertNotNil(recs.first { $0.title == "Critical Rest Day" })
    }

    func testThreeConsecutiveWorkoutsWithHighRPETriggersTaper() {
        let base = Date()
        let days = (0..<4).map { i in
            DailyHealthData(
                date: base.addingTimeInterval(TimeInterval(i) * 86400),
                source: .appleWatch,
                hrv: 50, restingHeartRate: 60
            )
        }
        DataStore.shared.history = days

        for day in days {
            let meta = UserMetadata(
                date: day.date,
                timeOfDay: .evening,
                workoutToday: true,
                workoutRPE: 8
            )
            MetadataStore.shared.save(meta)
        }

        let recs = engine.generateRecommendations(for: .appleWatch)
        XCTAssertNotNil(recs.first { $0.title == "Taper Recommended" })
    }

    func testHighReadinessLowStrainTriggersProgressiveOverload() {
        let day = DailyHealthData(
            date: Date(), source: .appleWatch,
            sleepHours: 8, sleepEfficiency: 0.92,
            deepSleepPercent: 0.18, remSleepPercent: 0.22,
            hrv: 75, hrvIsRMSSD: true,
            restingHeartRate: 48,
            activeCalories: 200, steps: 3000, workoutMinutes: 0
        )
        DataStore.shared.history = [day]

        let recs = engine.generateRecommendations(for: .appleWatch)
        XCTAssertNotNil(recs.first { $0.title == "Progressive Overload Window" })
    }

    func testHardWorkoutFollowedByLowHRVTriggersRecoveryWarning() {
        let base = Date()
        let day1 = DailyHealthData(
            date: base, source: .appleWatch,
            hrv: 50, restingHeartRate: 60
        )
        let day2 = DailyHealthData(
            date: base.addingTimeInterval(86400), source: .appleWatch,
            hrv: 30, restingHeartRate: 62
        )
        DataStore.shared.history = [day1, day2]

        let meta = UserMetadata(
            date: base,
            timeOfDay: .evening,
            workoutToday: true,
            workoutRPE: 9
        )
        MetadataStore.shared.save(meta)

        let recs = engine.generateRecommendations(for: .appleWatch)
        XCTAssertNotNil(recs.first { $0.title == "Recovery Warning" })
    }
}
