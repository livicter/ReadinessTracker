import XCTest
@testable import Readiness

final class GoogleHealthActiveCaloriesMapperTests: XCTestCase {

    private let fixtureJSON = """
    {
      "rollupDataPoints": [
        {
          "civilStartTime": { "date": { "year": 2026, "month": 9, "day": 28 }, "time": {} },
          "activeEnergyBurned": { "kcalSum": 420.5 }
        },
        {
          "civilStartTime": { "date": { "year": 2026, "month": 9, "day": 30 }, "time": {} },
          "activeEnergyBurned": { "kcalSum": 612.25 }
        }
      ]
    }
    """

    func testMapsLatestCivilDateKcalSum() throws {
        let kcal = try XCTUnwrap(GoogleHealthActiveCaloriesMapper.mapDailyRollupResponse(Data(fixtureJSON.utf8)))
        XCTAssertEqual(kcal, 612.25, accuracy: 0.001)
    }

    func testEmptyRollupReturnsNil() throws {
        XCTAssertNil(try GoogleHealthActiveCaloriesMapper.mapDailyRollupResponse(Data(#"{ "rollupDataPoints": [] }"#.utf8)))
    }

    func testStringKcalSum() throws {
        let data = Data(#"""
        { "rollupDataPoints": [ {
            "civilStartTime": { "date": { "year": 2026, "month": 1, "day": 2 } },
            "activeEnergyBurned": { "kcalSum": "501.5" }
        } ] }
        """#.utf8)
        XCTAssertEqual(try XCTUnwrap(GoogleHealthActiveCaloriesMapper.mapDailyRollupResponse(data)), 501.5, accuracy: 0.001)
    }

    func testZeroKcalReturnsNil() throws {
        let data = Data(#"""
        { "rollupDataPoints": [ {
            "civilStartTime": { "date": { "year": 2026, "month": 1, "day": 2 } },
            "activeEnergyBurned": { "kcalSum": 0 }
        } ] }
        """#.utf8)
        XCTAssertNil(try GoogleHealthActiveCaloriesMapper.mapDailyRollupResponse(data))
    }
}
