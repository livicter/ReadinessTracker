import XCTest
@testable import Readiness

final class GoogleHealthActiveMinutesMapperTests: XCTestCase {

    private let fixtureJSON = """
    {
      "rollupDataPoints": [
        {
          "civilStartTime": { "date": { "year": 2026, "month": 9, "day": 28 }, "time": {} },
          "activeMinutes": {
            "activeMinutesRollupByActivityLevel": [
              { "activityLevel": "LIGHTLY_ACTIVE", "activeMinutesSum": "20" },
              { "activityLevel": "MODERATELY_ACTIVE", "activeMinutesSum": "10" }
            ]
          }
        },
        {
          "civilStartTime": { "date": { "year": 2026, "month": 9, "day": 30 }, "time": {} },
          "activeMinutes": {
            "activeMinutesRollupByActivityLevel": [
              { "activityLevel": "LIGHTLY_ACTIVE", "activeMinutesSum": "40" },
              { "activityLevel": "VERY_ACTIVE", "activeMinutesSum": "15" }
            ]
          }
        }
      ]
    }
    """

    func testMapsLatestCivilDateSumAcrossLevels() throws {
        let minutes = try XCTUnwrap(GoogleHealthActiveMinutesMapper.mapDailyRollupResponse(Data(fixtureJSON.utf8)))
        XCTAssertEqual(minutes, 55, accuracy: 0.001)
    }

    func testEmptyRollupReturnsNil() throws {
        XCTAssertNil(try GoogleHealthActiveMinutesMapper.mapDailyRollupResponse(Data(#"{ "rollupDataPoints": [] }"#.utf8)))
    }

    func testMissingActiveMinutesReturnsNil() throws {
        let data = Data(#"{ "rollupDataPoints": [ { "civilStartTime": { "date": { "year": 2026, "month": 1, "day": 2 } } } ] }"#.utf8)
        XCTAssertNil(try GoogleHealthActiveMinutesMapper.mapDailyRollupResponse(data))
    }

    func testZeroSumsReturnNil() throws {
        let data = Data(#"""
        { "rollupDataPoints": [ {
            "civilStartTime": { "date": { "year": 2026, "month": 1, "day": 2 } },
            "activeMinutes": {
              "activeMinutesRollupByActivityLevel": [
                { "activityLevel": "LIGHTLY_ACTIVE", "activeMinutesSum": "0" }
              ]
            }
        } ] }
        """#.utf8)
        XCTAssertNil(try GoogleHealthActiveMinutesMapper.mapDailyRollupResponse(data))
    }

    func testNumericActiveMinutesSum() throws {
        let data = Data(#"""
        { "rollupDataPoints": [ {
            "civilStartTime": { "date": { "year": 2026, "month": 1, "day": 2 } },
            "activeMinutes": {
              "activeMinutesRollupByActivityLevel": [
                { "activityLevel": "MODERATELY_ACTIVE", "activeMinutesSum": 12 }
              ]
            }
        } ] }
        """#.utf8)
        XCTAssertEqual(try XCTUnwrap(GoogleHealthActiveMinutesMapper.mapDailyRollupResponse(data)), 12, accuracy: 0.001)
    }
}
