import XCTest
@testable import Readiness

final class SleepStageIntervalTests: XCTestCase {

    func testDurationMinutes() {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let end = start.addingTimeInterval(30 * 60)
        let interval = SleepStageInterval(stage: .deep, startDate: start, endDate: end)
        XCTAssertEqual(interval.durationMinutes, 30, accuracy: 0.001)
    }

    func testCodableRoundTrip() throws {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let interval = SleepStageInterval(stage: .rem, startDate: start, endDate: start.addingTimeInterval(1200))
        let data = try JSONEncoder().encode(interval)
        let decoded = try JSONDecoder().decode(SleepStageInterval.self, from: data)
        XCTAssertEqual(decoded, interval)
    }

    func testAllStageLabelsAndColorsExist() {
        // Compile-level guarantee that every case has label + color
        for stage in SleepStage.allCases {
            XCTAssertFalse(stage.label.isEmpty)
            _ = stage.color
        }
    }

    func testHealthKitStageMapping() {
        // Raw values from HKCategoryValueSleepAnalysis (HealthKit/HealthKit headers)
        XCTAssertEqual(SleepStageInterval.stage(forHealthKitValue: 0), .awake)   // awake
        XCTAssertEqual(SleepStageInterval.stage(forHealthKitValue: 1), .light)   // asleepUnspecified
        XCTAssertNil(SleepStageInterval.stage(forHealthKitValue: 2))             // inBed (not a sleep stage)
        XCTAssertEqual(SleepStageInterval.stage(forHealthKitValue: 3), .light)   // asleepCore
        XCTAssertEqual(SleepStageInterval.stage(forHealthKitValue: 4), .deep)    // asleepDeep
        XCTAssertEqual(SleepStageInterval.stage(forHealthKitValue: 5), .rem)     // asleepREM
        XCTAssertNil(SleepStageInterval.stage(forHealthKitValue: 99))
    }

    func testDailyHealthDataDefaultsSleepStagesToEmpty() {
        let day = DailyHealthData(date: Date(), source: .appleWatch)
        XCTAssertTrue(day.sleepStages.isEmpty)
    }

    func testDailyHealthDataLegacyDecodingWithoutSleepStages() throws {
        // Minimal legacy payload: no sleepStages key must still decode
        let json = """
        {
          "id": "00000000-0000-0000-0000-000000000001",
          "date": 700000000,
          "source": "Apple Watch",
          "sleepHours": 7.5
        }
        """.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        let day = try decoder.decode(DailyHealthData.self, from: json)
        XCTAssertTrue(day.sleepStages.isEmpty)
        XCTAssertEqual(day.sleepHours, 7.5, accuracy: 0.001)
    }
}
