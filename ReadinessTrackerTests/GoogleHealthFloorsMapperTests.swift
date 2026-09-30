import XCTest
@testable import Readiness

final class GoogleHealthFloorsMapperTests: XCTestCase {

    private let fixtureJSON = """
    {
      "rollupDataPoints": [
        {
          "civilStartTime": { "date": { "year": 2026, "month": 9, "day": 28 }, "time": {} },
          "floors": { "countSum": "8" }
        },
        {
          "civilStartTime": { "date": { "year": 2026, "month": 9, "day": 30 }, "time": {} },
          "floors": { "countSum": "14" }
        }
      ]
    }
    """

    func testMapsLatestCivilDateCountSum() throws {
        let floors = try XCTUnwrap(GoogleHealthFloorsMapper.mapDailyRollupResponse(Data(fixtureJSON.utf8)))
        XCTAssertEqual(floors, 14, accuracy: 0.001)
    }

    func testEmptyRollupReturnsNil() throws {
        XCTAssertNil(try GoogleHealthFloorsMapper.mapDailyRollupResponse(Data(#"{ "rollupDataPoints": [] }"#.utf8)))
    }

    func testMissingFloorsReturnsNil() throws {
        let data = Data(#"{ "rollupDataPoints": [ { "civilStartTime": { "date": { "year": 2026, "month": 1, "day": 2 } } } ] }"#.utf8)
        XCTAssertNil(try GoogleHealthFloorsMapper.mapDailyRollupResponse(data))
    }

    func testZeroCountSumReturnsNil() throws {
        let data = Data(#"""
        { "rollupDataPoints": [ {
            "civilStartTime": { "date": { "year": 2026, "month": 1, "day": 2 } },
            "floors": { "countSum": "0" }
        } ] }
        """#.utf8)
        XCTAssertNil(try GoogleHealthFloorsMapper.mapDailyRollupResponse(data))
    }

    func testNumericCountSum() throws {
        let data = Data(#"""
        { "rollupDataPoints": [ {
            "civilStartTime": { "date": { "year": 2026, "month": 1, "day": 2 } },
            "floors": { "countSum": 11 }
        } ] }
        """#.utf8)
        XCTAssertEqual(try XCTUnwrap(GoogleHealthFloorsMapper.mapDailyRollupResponse(data)), 11, accuracy: 0.001)
    }
}
