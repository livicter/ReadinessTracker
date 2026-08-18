import XCTest
@testable import Readiness

final class NutritionSummaryTests: XCTestCase {
    func testNutritionSummaryEncodingRoundTrip() throws {
        let summary = NutritionSummary(waterLiters: 2.5, caffeineMg: 120, proteinGrams: 80)
        let encoded = try JSONEncoder().encode(summary)
        let decoded = try JSONDecoder().decode(NutritionSummary.self, from: encoded)
        XCTAssertEqual(decoded.waterLiters, 2.5)
        XCTAssertEqual(decoded.caffeineMg, 120)
        XCTAssertEqual(decoded.proteinGrams, 80)
    }
    
    func testNutritionSummaryIsEmpty() {
        XCTAssertTrue(NutritionSummary().isEmpty)
        XCTAssertFalse(NutritionSummary(waterLiters: 1.0).isEmpty)
    }
}
