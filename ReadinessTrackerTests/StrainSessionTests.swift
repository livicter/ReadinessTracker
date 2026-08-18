import XCTest
@testable import Readiness

final class StrainSessionTests: XCTestCase {
    func testWorkoutTRIMPFromHRSamples() {
        let base = Date()
        let samples = (0..<30).map { i in
            HRSample(timestamp: base.addingTimeInterval(TimeInterval(i * 60)), bpm: 160)
        }
        let data = DailyHealthData(
            date: base, source: .appleWatch,
            restingHeartRate: 60,
            maxHeartRate: 190,
            hrSamples: samples
        )
        let session = StrainSession(workoutType: "Running", startDate: base, endDate: base.addingTimeInterval(30 * 60))
        let trimp = StrainCalculator.trimp(for: session, using: data)
        XCTAssertGreaterThan(trimp, 0)
    }
    
    func testWorkoutOutsideSamplesReturnsZero() {
        let base = Date()
        let samples = (0..<10).map { i in
            HRSample(timestamp: base.addingTimeInterval(TimeInterval(i * 60)), bpm: 160)
        }
        let data = DailyHealthData(
            date: base, source: .appleWatch,
            restingHeartRate: 60,
            maxHeartRate: 190,
            hrSamples: samples
        )
        let later = base.addingTimeInterval(3600)
        let session = StrainSession(workoutType: "Running", startDate: later, endDate: later.addingTimeInterval(30 * 60))
        let trimp = StrainCalculator.trimp(for: session, using: data)
        XCTAssertEqual(trimp, 0, accuracy: 0.1)
    }
    
    func testDailyDataEncodesStrainSessions() throws {
        let session = StrainSession(workoutType: "Cycling", startDate: Date(), endDate: Date().addingTimeInterval(1800))
        let data = DailyHealthData(date: Date(), source: .appleWatch, strainSessions: [session])
        let encoded = try JSONEncoder().encode(data)
        let decoded = try JSONDecoder().decode(DailyHealthData.self, from: encoded)
        XCTAssertEqual(decoded.strainSessions.count, 1)
        XCTAssertEqual(decoded.strainSessions.first?.workoutType, "Cycling")
    }
}
