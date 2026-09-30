import XCTest
@testable import Readiness

final class GoogleHealthDistanceMapperTests: XCTestCase {

    private let fixtureJSON = """
    {
      "rollupDataPoints": [
        {
          "civilStartTime": { "date": { "year": 2026, "month": 9, "day": 28 }, "time": {} },
          "distance": { "millimetersSum": "4520000" }
        },
        {
          "civilStartTime": { "date": { "year": 2026, "month": 9, "day": 30 }, "time": {} },
          "distance": { "millimetersSum": "7850000" }
        }
      ]
    }
    """

    func testMapsLatestCivilDateMillimetersToKm() throws {
        let km = try XCTUnwrap(GoogleHealthDistanceMapper.mapDailyRollupResponse(Data(fixtureJSON.utf8)))
        XCTAssertEqual(km, 7.85, accuracy: 0.0001)
    }

    func testEmptyRollupReturnsNil() throws {
        XCTAssertNil(try GoogleHealthDistanceMapper.mapDailyRollupResponse(Data(#"{ "rollupDataPoints": [] }"#.utf8)))
    }

    func testMissingDistanceReturnsNil() throws {
        let data = Data(#"{ "rollupDataPoints": [ { "civilStartTime": { "date": { "year": 2026, "month": 1, "day": 2 } } } ] }"#.utf8)
        XCTAssertNil(try GoogleHealthDistanceMapper.mapDailyRollupResponse(data))
    }

    func testZeroMillimetersReturnsNil() throws {
        let data = Data(#"""
        { "rollupDataPoints": [ {
            "civilStartTime": { "date": { "year": 2026, "month": 1, "day": 2 } },
            "distance": { "millimetersSum": "0" }
        } ] }
        """#.utf8)
        XCTAssertNil(try GoogleHealthDistanceMapper.mapDailyRollupResponse(data))
    }

    func testNumericMillimetersSum() throws {
        let data = Data(#"""
        { "rollupDataPoints": [ {
            "civilStartTime": { "date": { "year": 2026, "month": 1, "day": 2 } },
            "distance": { "millimetersSum": 3210000 }
        } ] }
        """#.utf8)
        XCTAssertEqual(try XCTUnwrap(GoogleHealthDistanceMapper.mapDailyRollupResponse(data)), 3.21, accuracy: 0.0001)
    }

    func testOneKmExact() throws {
        let data = Data(#"""
        { "rollupDataPoints": [ {
            "civilStartTime": { "date": { "year": 2026, "month": 1, "day": 2 } },
            "distance": { "millimetersSum": "1000000" }
        } ] }
        """#.utf8)
        XCTAssertEqual(try XCTUnwrap(GoogleHealthDistanceMapper.mapDailyRollupResponse(data)), 1.0, accuracy: 0.0001)
    }
}
