import XCTest
@testable import Readiness

/// Honest #43: shared export hook after DataStore + MetadataStore writes.
@MainActor
final class WidgetExportAfterWriteTests: XCTestCase {
    override func tearDown() async throws {
        WidgetExportAfterWrite.testPerform = nil
        try await super.tearDown()
    }

    func testRunInvokesInjectedPerformWithProvidedStore() {
        var seen: DataStore?
        let store = DataStore.shared
        WidgetExportAfterWrite.testPerform = { seen = $0 }
        WidgetExportAfterWrite.run(dataStore: store)
        XCTAssertTrue(seen === store)
    }

    func testDataStoreSaveInvokesExportAfterWrite() {
        var count = 0
        WidgetExportAfterWrite.testPerform = { _ in count += 1 }

        DataStore.shared.save(
            DailyHealthData(
                date: Date(),
                source: .appleWatch,
                sleepHours: 7.2,
                hrv: 55,
                restingHeartRate: 58
            )
        )

        XCTAssertEqual(count, 1, "HealthKit/Fitbit DataStore.save must hit WidgetExportAfterWrite")
    }

    func testMetadataStoreSaveInvokesExportAfterWrite() {
        var count = 0
        WidgetExportAfterWrite.testPerform = { _ in count += 1 }

        MetadataStore.shared.save(
            UserMetadata(
                date: Date(),
                timeOfDay: .morning,
                subjectiveFeel: 4,
                workloadStress: 2,
                mentalFatigue: 2
            )
        )

        XCTAssertEqual(
            count,
            1,
            "Morning/Evening Check-in MetadataStore.save must hit WidgetExportAfterWrite"
        )
    }

    func testEveningCheckInAlsoInvokesExportAfterWrite() {
        var count = 0
        WidgetExportAfterWrite.testPerform = { _ in count += 1 }

        MetadataStore.shared.save(
            UserMetadata(
                date: Date(),
                timeOfDay: .evening,
                workoutToday: true,
                workoutRPE: 7,
                workoutDurationMinutes: 45
            )
        )

        XCTAssertEqual(count, 1, "Evening Check-in must refresh widget export path")
    }
}
