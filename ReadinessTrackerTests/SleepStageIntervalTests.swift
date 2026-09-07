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

    func testUIFixtureCoherentSleepStagesMatchWakeEpisodes() {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let previous = cal.date(byAdding: .day, value: -1, to: today)!
        let start = cal.date(bySettingHour: 23, minute: 5, second: 0, of: previous)!
        let end = cal.date(bySettingHour: 7, minute: 10, second: 0, of: today)!

        let stages = UIFixture.coherentSleepStages(sleepStart: start, sleepEnd: end)
        XCTAssertFalse(stages.isEmpty)
        XCTAssertEqual(stages.filter { $0.stage == .awake }.count, 1)
        XCTAssertEqual(stages.first?.startDate, start)
        XCTAssertEqual(stages.last?.endDate, end)

        let awake = SleepCycleDetector.awakePeriods(from: stages)
        XCTAssertEqual(awake.count, 1)

        let history = UIFixture.history()
        XCTAssertEqual(history.count, 14)
        for day in history {
            XCTAssertFalse(day.sleepStages.isEmpty, "fixture day must seed stages for hypnogram honesty")
            XCTAssertEqual(
                day.wakeEpisodes,
                SleepCycleDetector.awakePeriods(from: day.sleepStages).count,
                "wakeEpisodes must match awake periods derived from stages"
            )
            XCTAssertEqual(day.wakeEpisodes, 1)
        }
    }

    func testHypnogramYBandsMatchChartDomain() {
        // chartYScale domain is -4...0; bands must sit inside it (not positive depthRank).
        XCTAssertEqual(SleepStage.awake.hypnogramYStart, -1)
        XCTAssertEqual(SleepStage.awake.hypnogramYEnd, 0)
        XCTAssertEqual(SleepStage.rem.hypnogramYStart, -2)
        XCTAssertEqual(SleepStage.rem.hypnogramYEnd, -1)
        XCTAssertEqual(SleepStage.light.hypnogramYStart, -3)
        XCTAssertEqual(SleepStage.light.hypnogramYEnd, -2)
        XCTAssertEqual(SleepStage.deep.hypnogramYStart, -4)
        XCTAssertEqual(SleepStage.deep.hypnogramYEnd, -3)
        for stage in SleepStage.allCases {
            XCTAssertLessThanOrEqual(stage.hypnogramYStart, 0)
            XCTAssertGreaterThanOrEqual(stage.hypnogramYStart, -4)
            XCTAssertLessThanOrEqual(stage.hypnogramYEnd, 0)
            XCTAssertGreaterThanOrEqual(stage.hypnogramYEnd, -4)
            XCTAssertEqual(stage.hypnogramYEnd - stage.hypnogramYStart, 1)
        }
    }
}
