import XCTest
@testable import Readiness

final class StrainCalculatorTests: XCTestCase {
    func testNoDataReturnsFallbackStrain() {
        let data = DailyHealthData(date: Date(), source: .appleWatch)
        let strain = StrainCalculator.calculate(from: data, history: [])
        XCTAssertEqual(strain, 0, accuracy: 0.1)
    }

    func testCaloriesAndWorkoutProduceFallbackStrain() {
        let data = DailyHealthData(date: Date(), source: .appleWatch, activeCalories: 3000, workoutMinutes: 60)
        let strain = StrainCalculator.calculate(from: data, history: [])
        XCTAssertEqual(strain, 15 + 2, accuracy: 0.1)
    }

    func testHRSamplesCapAt21() {
        let samples = (0..<600).map { i in
            HRSample(timestamp: Date().addingTimeInterval(TimeInterval(i * 60)), bpm: 180)
        }
        let data = DailyHealthData(date: Date(), source: .appleWatch, restingHeartRate: 60, maxHeartRate: 190, hrSamples: samples)
        let strain = StrainCalculator.calculate(from: data, history: [])
        XCTAssertLessThanOrEqual(strain, 21)
    }

    func testWorkoutTRIMPOnlyUsesSamplesInsideInterval() {
        let base = Date()
        let inside = (0..<10).map { i in
            HRSample(timestamp: base.addingTimeInterval(TimeInterval(i * 60)), bpm: 160)
        }
        let outside = (10..<20).map { i in
            HRSample(timestamp: base.addingTimeInterval(TimeInterval(i * 60) + 3600), bpm: 160)
        }
        let data = DailyHealthData(
            date: base, source: .appleWatch,
            restingHeartRate: 60,
            maxHeartRate: 190,
            hrSamples: inside + outside
        )
        let session = StrainSession(workoutType: "Running", startDate: base, endDate: base.addingTimeInterval(10 * 60))
        let trimp = StrainCalculator.trimp(for: session, using: data)
        XCTAssertGreaterThan(trimp, 0)
        // If all samples were counted, TRIMP would be roughly double.
        let fullDay = DailyHealthData(
            date: base, source: .appleWatch,
            restingHeartRate: 60,
            maxHeartRate: 190,
            hrSamples: inside + outside
        )
        let fullTrimp = StrainCalculator.trimp(for: StrainSession(workoutType: "Running", startDate: base, endDate: base.addingTimeInterval(3600 + 20 * 60)), using: fullDay)
        XCTAssertGreaterThan(fullTrimp, trimp)
    }

    func testEnrichSessionsComputesNonZeroTRIMPForInsideSamples() {
        let base = Date()
        let samples = (0..<30).map { i in
            HRSample(timestamp: base.addingTimeInterval(TimeInterval(i * 60)), bpm: 160)
        }
        let session = StrainSession(workoutType: "Running", startDate: base, endDate: base.addingTimeInterval(30 * 60))
        let enriched = StrainCalculator.enrichSessions([session], hrSamples: samples, restingHR: 60, maxHR: 190)
        XCTAssertEqual(enriched.count, 1)
        XCTAssertGreaterThan(enriched[0].trimp, 0)
    }

    func testEnrichSessionsComputesZeroTRIMPForOutsideWorkout() {
        let base = Date()
        let samples = (0..<10).map { i in
            HRSample(timestamp: base.addingTimeInterval(TimeInterval(i * 60)), bpm: 160)
        }
        let later = base.addingTimeInterval(3600)
        let session = StrainSession(workoutType: "Running", startDate: later, endDate: later.addingTimeInterval(30 * 60))
        let enriched = StrainCalculator.enrichSessions([session], hrSamples: samples, restingHR: 60, maxHR: 190)
        XCTAssertEqual(enriched[0].trimp, 0, accuracy: 0.1)
    }

    func testEnrichSessionsContributionSumsToDailyStrain() {
        let base = Date()
        let firstSamples = (0..<30).map { i in
            HRSample(timestamp: base.addingTimeInterval(TimeInterval(i * 60)), bpm: 160)
        }
        let secondBase = base.addingTimeInterval(3600)
        let secondSamples = (30..<60).map { i in
            HRSample(timestamp: secondBase.addingTimeInterval(TimeInterval((i - 30) * 60)), bpm: 140)
        }
        let session1 = StrainSession(workoutType: "Running", startDate: base, endDate: base.addingTimeInterval(30 * 60))
        let session2 = StrainSession(workoutType: "Cycling", startDate: secondBase, endDate: secondBase.addingTimeInterval(30 * 60))
        let allSamples = firstSamples + secondSamples
        let enriched = StrainCalculator.enrichSessions([session1, session2], hrSamples: allSamples, restingHR: 60, maxHR: 190)

        let placeholderData = DailyHealthData(
            date: base, source: .appleWatch,
            restingHeartRate: 60,
            maxHeartRate: 190,
            hrSamples: allSamples,
            strainSessions: [session1, session2]
        )
        let expectedDailyStrain = StrainCalculator.calculate(from: placeholderData, history: [])

        let totalContribution = enriched.map(\.contribution).reduce(0, +)
        XCTAssertEqual(totalContribution, expectedDailyStrain, accuracy: 0.01)
    }

    func testEnrichSessionsEqualWorkoutsSplitDailyStrain() {
        let base = Date()
        let firstSamples = (0..<30).map { i in
            HRSample(timestamp: base.addingTimeInterval(TimeInterval(i * 60)), bpm: 160)
        }
        let secondBase = base.addingTimeInterval(3600)
        let secondSamples = (30..<60).map { i in
            HRSample(timestamp: secondBase.addingTimeInterval(TimeInterval((i - 30) * 60)), bpm: 160)
        }
        let session1 = StrainSession(workoutType: "Running", startDate: base, endDate: base.addingTimeInterval(30 * 60))
        let session2 = StrainSession(workoutType: "Cycling", startDate: secondBase, endDate: secondBase.addingTimeInterval(30 * 60))
        let allSamples = firstSamples + secondSamples
        let enriched = StrainCalculator.enrichSessions([session1, session2], hrSamples: allSamples, restingHR: 60, maxHR: 190)

        let placeholderData = DailyHealthData(
            date: base, source: .appleWatch,
            restingHeartRate: 60,
            maxHeartRate: 190,
            hrSamples: allSamples,
            strainSessions: [session1, session2]
        )
        let expectedDailyStrain = StrainCalculator.calculate(from: placeholderData, history: [])

        XCTAssertEqual(enriched[0].contribution, expectedDailyStrain / 2, accuracy: 0.01)
        XCTAssertEqual(enriched[1].contribution, expectedDailyStrain / 2, accuracy: 0.01)
    }

    func testEnrichSessionsFallsBackToDurationWhenNoHRSamples() {
        let base = Date()
        let session1 = StrainSession(workoutType: "Running", startDate: base, endDate: base.addingTimeInterval(30 * 60))
        let session2 = StrainSession(workoutType: "Cycling", startDate: base.addingTimeInterval(3600), endDate: base.addingTimeInterval(3600 + 30 * 60))
        let enriched = StrainCalculator.enrichSessions([session1, session2], hrSamples: [], restingHR: 60, maxHR: 190)
        let totalContribution = enriched.map(\.contribution).reduce(0, +)
        XCTAssertGreaterThan(totalContribution, 0)
        // Equal durations -> equal contribution
        XCTAssertEqual(enriched[0].contribution, enriched[1].contribution, accuracy: 0.01)
    }
}
