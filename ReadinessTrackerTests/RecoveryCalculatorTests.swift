import XCTest
@testable import Readiness

final class RecoveryCalculatorTests: XCTestCase {
    func testPerfectRecovery() {
        let data = DailyHealthData(
            date: Date(), source: .appleWatch,
            sleepHours: 8, sleepEfficiency: 0.92,
            deepSleepPercent: 0.18, remSleepPercent: 0.22,
            hrv: 70, restingHeartRate: 50,
            activeCalories: 200, steps: 3000, workoutMinutes: 0
        )
        let history = [data]
        let score = RecoveryCalculator.calculate(from: data, history: history)
        XCTAssertGreaterThan(score, 80)
    }

    func testPoorRecovery() {
        let data = DailyHealthData(
            date: Date(), source: .appleWatch,
            sleepHours: 5, sleepEfficiency: 0.70,
            deepSleepPercent: 0.05, remSleepPercent: 0.10,
            hrv: 25, restingHeartRate: 75,
            activeCalories: 50, steps: 1000, workoutMinutes: 0
        )
        let history = [data]
        let score = RecoveryCalculator.calculate(from: data, history: history)
        XCTAssertLessThan(score, 40)
    }

    func testRecoveryUsesRMSSDWhenFlagSet() {
        // Same HRV value as SDNN test, but flagged as RMSSD should produce identical score path.
        let data = DailyHealthData(
            date: Date(), source: .appleWatch,
            sleepHours: 8, sleepEfficiency: 0.92,
            deepSleepPercent: 0.18, remSleepPercent: 0.22,
            hrv: 70, hrvIsRMSSD: true,
            restingHeartRate: 50,
            activeCalories: 200, steps: 3000, workoutMinutes: 0
        )
        let history = [data]
        let score = RecoveryCalculator.calculate(from: data, history: history)
        XCTAssertGreaterThan(score, 80)
    }

    func testPerfectSpO2() {
        let data = DailyHealthData(
            date: Date(), source: .appleWatch,
            sleepHours: 8, sleepEfficiency: 0.92,
            deepSleepPercent: 0.18, remSleepPercent: 0.22,
            hrv: 70, hrvIsRMSSD: true,
            restingHeartRate: 50,
            activeCalories: 200, steps: 3000, workoutMinutes: 0,
            bloodOxygen: 99
        )
        let breakdown = RecoveryCalculator.calculateBreakdown(from: data, history: [data])
        XCTAssertEqual(breakdown.spo2Score, 100)
    }

    func testLowSpO2() {
        let data = DailyHealthData(
            date: Date(), source: .appleWatch,
            sleepHours: 8, sleepEfficiency: 0.92,
            deepSleepPercent: 0.18, remSleepPercent: 0.22,
            hrv: 70, hrvIsRMSSD: true,
            restingHeartRate: 50,
            activeCalories: 200, steps: 3000, workoutMinutes: 0,
            bloodOxygen: 88
        )
        let breakdown = RecoveryCalculator.calculateBreakdown(from: data, history: [data])
        XCTAssertEqual(breakdown.spo2Score, 0)
    }

    func testMenstrualAdjustment() {
        var settings = UserSettings.load()
        settings.trackMenstrualCycle = true
        settings.save()

        addTeardownBlock {
            var settings = UserSettings.load()
            settings.trackMenstrualCycle = false
            settings.save()
        }

        let data = DailyHealthData(
            date: Date(), source: .appleWatch,
            sleepHours: 8, sleepEfficiency: 0.92,
            deepSleepPercent: 0.18, remSleepPercent: 0.22,
            hrv: 70, hrvIsRMSSD: true,
            restingHeartRate: 50,
            activeCalories: 200, steps: 3000, workoutMinutes: 0,
            menstrualFlow: true
        )
        let withoutFlow = RecoveryCalculator.calculate(from: DailyHealthData(date: Date(), source: .appleWatch, sleepHours: 8, sleepEfficiency: 0.92, deepSleepPercent: 0.18, remSleepPercent: 0.22, hrv: 70, hrvIsRMSSD: true, restingHeartRate: 50, activeCalories: 200, steps: 3000, workoutMinutes: 0), history: [data])
        let withFlow = RecoveryCalculator.calculate(from: data, history: [data])
        XCTAssertEqual(withoutFlow - withFlow, 3)
    }
}
