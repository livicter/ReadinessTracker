import XCTest
@testable import Readiness

final class NutritionSummaryTests: XCTestCase {
    func testNutritionSummaryEncodingRoundTrip() throws {
        let summary = NutritionSummary(waterLiters: 2.5, caffeineMg: 120, proteinGrams: 80, energyKcal: 2100, carbohydrateGrams: 210, fatGrams: 68, fiberGrams: 28, sugarGrams: 42, alcoholicBeverages: 1)
        let encoded = try JSONEncoder().encode(summary)
        let decoded = try JSONDecoder().decode(NutritionSummary.self, from: encoded)
        XCTAssertEqual(decoded.waterLiters, 2.5)
        XCTAssertEqual(decoded.caffeineMg, 120)
        XCTAssertEqual(decoded.proteinGrams, 80)
        XCTAssertEqual(decoded.energyKcal, 2100)
        XCTAssertEqual(decoded.carbohydrateGrams, 210)
        XCTAssertEqual(decoded.fatGrams, 68)
        XCTAssertEqual(decoded.fiberGrams, 28)
        XCTAssertEqual(decoded.sugarGrams, 42)
        XCTAssertEqual(decoded.alcoholicBeverages, 1)
    }
    
    func testNutritionSummaryIsEmpty() {
        XCTAssertTrue(NutritionSummary().isEmpty)
        XCTAssertFalse(NutritionSummary(waterLiters: 1.0).isEmpty)
        XCTAssertFalse(NutritionSummary(energyKcal: 1800).isEmpty)
    }
}
