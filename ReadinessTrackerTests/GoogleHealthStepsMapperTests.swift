import XCTest
@testable import Readiness

final class GoogleHealthStepsMapperTests: XCTestCase {

    private let fixtureJSON = """
    {
      "rollupDataPoints": [
        {
          "civilStartTime": { "date": { "year": 2026, "month": 9, "day": 28 }, "time": {} },
          "steps": { "countSum": "8430" }
        },
        {
          "civilStartTime": { "date": { "year": 2026, "month": 9, "day": 30 }, "time": {} },
          "steps": { "countSum": "11245" }
        }
      ]
    }
    """

    func testMapsLatestCivilDateCountSum() throws {
        let steps = try XCTUnwrap(GoogleHealthStepsMapper.mapDailyRollupResponse(Data(fixtureJSON.utf8)))
        XCTAssertEqual(steps, 11245)
    }

    func testEmptyRollupReturnsNil() throws {
        XCTAssertNil(try GoogleHealthStepsMapper.mapDailyRollupResponse(Data(#"{ "rollupDataPoints": [] }"#.utf8)))
    }

    func testMissingStepsReturnsNil() throws {
        let data = Data(#"{ "rollupDataPoints": [ { "civilStartTime": { "date": { "year": 2026, "month": 1, "day": 2 } } } ] }"#.utf8)
        XCTAssertNil(try GoogleHealthStepsMapper.mapDailyRollupResponse(data))
    }

    func testZeroCountSumReturnsNil() throws {
        let data = Data(#"""
        { "rollupDataPoints": [ {
            "civilStartTime": { "date": { "year": 2026, "month": 1, "day": 2 } },
            "steps": { "countSum": "0" }
        } ] }
        """#.utf8)
        XCTAssertNil(try GoogleHealthStepsMapper.mapDailyRollupResponse(data))
    }

    func testNumericCountSum() throws {
        let data = Data(#"""
        { "rollupDataPoints": [ {
            "civilStartTime": { "date": { "year": 2026, "month": 1, "day": 2 } },
            "steps": { "countSum": 9912 }
        } ] }
        """#.utf8)
        XCTAssertEqual(try XCTUnwrap(GoogleHealthStepsMapper.mapDailyRollupResponse(data)), 9912)
    }

    func testDailyRollupRequestBodyContainsCivilRange() throws {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = cal.date(from: DateComponents(year: 2026, month: 10, day: 1, hour: 8))!
        let data = try XCTUnwrap(GoogleHealthDailyRollupRequest.todayCivilRangeJSON(now: now, calendar: cal))
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(json["windowSizeDays"] as? Int, 1)
        XCTAssertEqual(json["dataSourceFamily"] as? String, "users/me/dataSourceFamilies/google-sources")
        let range = try XCTUnwrap(json["range"] as? [String: Any])
        let start = try XCTUnwrap((range["start"] as? [String: Any])?["date"] as? [String: Any])
        let end = try XCTUnwrap((range["end"] as? [String: Any])?["date"] as? [String: Any])
        XCTAssertEqual(start["year"] as? Int, 2026)
        XCTAssertEqual(start["month"] as? Int, 10)
        XCTAssertEqual(start["day"] as? Int, 1)
        XCTAssertEqual(end["day"] as? Int, 2)
    }
}
