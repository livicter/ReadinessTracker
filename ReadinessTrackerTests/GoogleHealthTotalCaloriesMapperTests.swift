import XCTest
@testable import Readiness

final class GoogleHealthTotalCaloriesMapperTests: XCTestCase {

    private let fixtureJSON = """
    {
      "rollupDataPoints": [
        {
          "civilStartTime": { "date": { "year": 2026, "month": 9, "day": 28 }, "time": {} },
          "totalCalories": { "kcalSum": 2100.5 }
        },
        {
          "civilStartTime": { "date": { "year": 2026, "month": 9, "day": 30 }, "time": {} },
          "totalCalories": { "kcalSum": 2450.0 }
        }
      ]
    }
    """

    func testMapsLatestCivilDateKcalSum() throws {
        let kcal = try XCTUnwrap(GoogleHealthTotalCaloriesMapper.mapDailyRollupResponse(Data(fixtureJSON.utf8)))
        XCTAssertEqual(kcal, 2450.0, accuracy: 0.001)
    }

    func testEmptyRollupReturnsNil() throws {
        XCTAssertNil(try GoogleHealthTotalCaloriesMapper.mapDailyRollupResponse(Data(#"{ "rollupDataPoints": [] }"#.utf8)))
    }

    func testMissingTotalCaloriesReturnsNil() throws {
        let data = Data(#"{ "rollupDataPoints": [ { "civilStartTime": { "date": { "year": 2026, "month": 1, "day": 2 } } } ] }"#.utf8)
        XCTAssertNil(try GoogleHealthTotalCaloriesMapper.mapDailyRollupResponse(data))
    }

    func testZeroKcalSumReturnsNil() throws {
        let data = Data(#"""
        { "rollupDataPoints": [ {
            "civilStartTime": { "date": { "year": 2026, "month": 1, "day": 2 } },
            "totalCalories": { "kcalSum": 0 }
        } ] }
        """#.utf8)
        XCTAssertNil(try GoogleHealthTotalCaloriesMapper.mapDailyRollupResponse(data))
    }
}
