import XCTest
@testable import Readiness

final class CoachingEngineTests: XCTestCase {

    private func makeDay(
        daysAgo: Int,
        sleepHours: Double = 8,
        sleepEfficiency: Double = 0.92,
        deepSleepPercent: Double = 0.18,
        remSleepPercent: Double = 0.22,
        hrv: Double = 50,
        restingHeartRate: Double = 60,
        nutrition: NutritionSummary = NutritionSummary()
    ) -> DailyHealthData {
        DailyHealthData(
            date: Date().addingTimeInterval(TimeInterval(-daysAgo) * 86400),
            source: .appleWatch,
            sleepHours: sleepHours,
            sleepEfficiency: sleepEfficiency,
            deepSleepPercent: deepSleepPercent,
            remSleepPercent: remSleepPercent,
            hrv: hrv,
            restingHeartRate: restingHeartRate,
            nutrition: nutrition
        )
    }

    func testLowHRVProducesHRVInsight() {
        var history = (1...9).reversed().map { makeDay(daysAgo: $0) }
        history.append(makeDay(daysAgo: 0, hrv: 35))

        let feed = CoachingEngine.generateFeed(latest: history.last!, history: history)
        let hrvInsight = feed.first { $0.category == .hrv }
        XCTAssertNotNil(hrvInsight)
        XCTAssertTrue(hrvInsight?.title.contains("below your 30-day baseline") == true)
    }

    func testReadinessDropNamesSleepDriver() {
        var history = (1...7).reversed().map { makeDay(daysAgo: $0) }
        history.append(makeDay(
            daysAgo: 0,
            sleepHours: 5,
            sleepEfficiency: 0.70,
            deepSleepPercent: 0.08,
            remSleepPercent: 0.10
        ))

        let feed = CoachingEngine.generateFeed(latest: history.last!, history: history)
        let trend = feed.first { $0.title.contains("vs your 7-day average") }
        XCTAssertNotNil(trend)
        XCTAssertTrue(trend?.title.contains("down") == true)
        XCTAssertTrue(trend?.explanation.contains("Sleep") == true)
    }

    func testFeedSortedByImpactDescending() {
        var history = (1...9).reversed().map { makeDay(daysAgo: $0) }
        history.append(makeDay(
            daysAgo: 0,
            sleepHours: 5,
            sleepEfficiency: 0.70,
            hrv: 35,
            restingHeartRate: 68,
            nutrition: NutritionSummary(waterLiters: 0.5, caffeineMg: 400)
        ))

        let feed = CoachingEngine.generateFeed(latest: history.last!, history: history)
        XCTAssertGreaterThan(feed.count, 1)
        for (a, b) in zip(feed, feed.dropFirst()) {
            XCTAssertGreaterThanOrEqual(a.impact, b.impact)
        }
    }

    func testJournalBehaviorImpactProducesInsight() {
        let history = (0...6).reversed().map { makeDay(daysAgo: $0) }
        let now = Date()
        let entries = [
            JournalEntry(date: now.addingTimeInterval(-4 * 86400), behaviors: [.alcohol], notes: "", readinessScore: 50),
            JournalEntry(date: now.addingTimeInterval(-3 * 86400), behaviors: [.alcohol], notes: "", readinessScore: 50),
            JournalEntry(date: now.addingTimeInterval(-2 * 86400), behaviors: [], notes: "", readinessScore: 75),
            JournalEntry(date: now.addingTimeInterval(-1 * 86400), behaviors: [], notes: "", readinessScore: 75)
        ]

        let feed = CoachingEngine.generateFeed(
            latest: history.last!,
            history: history,
            journalEntries: entries
        )
        let behaviorInsight = feed.first { $0.category == .behavior }
        XCTAssertNotNil(behaviorInsight)
        XCTAssertTrue(behaviorInsight?.title.contains("Alcohol") == true)
    }

    func testLowWaterProducesNutritionInsight() {
        let history = (0...6).reversed().map {
            makeDay(daysAgo: $0, nutrition: NutritionSummary(waterLiters: 1.0))
        }

        let feed = CoachingEngine.generateFeed(latest: history.last!, history: history)
        XCTAssertNotNil(feed.first { $0.category == .nutrition && $0.title == "Hydration is low" })
    }

    func testTrainingGuidanceCardPresent() {
        let history = (0...6).reversed().map { makeDay(daysAgo: $0) }

        let feed = CoachingEngine.generateFeed(
            latest: history.last!,
            history: history,
            trainingGuidance: "Rest day recommended. Active recovery only (walk, stretch, yoga)."
        )
        let guidance = feed.first { $0.category == .training }
        XCTAssertNotNil(guidance)
        XCTAssertTrue(guidance?.action.contains("Rest day") == true)
    }
}
