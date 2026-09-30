import XCTest
@testable import Readiness

final class GoogleHealthSkinTempMapperTests: XCTestCase {

    private let fixtureJSON = """
    {
      "dataPoints": [
        {
          "name": "users/me/dataTypes/daily-sleep-temperature-derivations/dataPoints/st-older",
          "dailySleepTemperatureDerivations": {
            "date": { "year": 2026, "month": 9, "day": 28 },
            "nightlyTemperatureCelsius": 33.8,
            "baselineTemperatureCelsius": 34.0,
            "relativeNightlyStddev30dCelsius": 0.15
          }
        },
        {
          "name": "users/me/dataTypes/daily-sleep-temperature-derivations/dataPoints/st-today",
          "dailySleepTemperatureDerivations": {
            "date": { "year": 2026, "month": 9, "day": 30 },
            "nightlyTemperatureCelsius": 34.25,
            "baselineTemperatureCelsius": 34.0,
            "relativeNightlyStddev30dCelsius": 0.12
          }
        }
      ]
    }
    """

    func testMapsLatestNightlyAbsoluteCelsius() throws {
        let c = try XCTUnwrap(GoogleHealthSkinTempMapper.mapListResponse(Data(fixtureJSON.utf8)))
        XCTAssertEqual(c, 34.25, accuracy: 0.001)
    }

    func testEmptyDataPointsReturnsNil() throws {
        XCTAssertNil(try GoogleHealthSkinTempMapper.mapListResponse(Data(#"{ "dataPoints": [] }"#.utf8)))
    }

    func testMissingPayloadReturnsNil() throws {
        XCTAssertNil(try GoogleHealthSkinTempMapper.mapListResponse(Data(#"{ "dataPoints": [ { "name": "x" } ] }"#.utf8)))
    }

    func testStringNightlyTemperature() throws {
        let data = Data(#"""
        { "dataPoints": [ {
            "dailySleepTemperatureDerivations": {
              "date": { "year": 2026, "month": 1, "day": 2 },
              "nightlyTemperatureCelsius": "33.9"
            }
        } ] }
        """#.utf8)
        XCTAssertEqual(try XCTUnwrap(GoogleHealthSkinTempMapper.mapListResponse(data)), 33.9, accuracy: 0.001)
    }

    func testOutOfPhysiologicalRangeReturnsNil() throws {
        let cold = Data(#"""
        { "dataPoints": [ {
            "dailySleepTemperatureDerivations": {
              "date": { "year": 2026, "month": 1, "day": 2 },
              "nightlyTemperatureCelsius": 10
            }
        } ] }
        """#.utf8)
        let hot = Data(#"""
        { "dataPoints": [ {
            "dailySleepTemperatureDerivations": {
              "date": { "year": 2026, "month": 1, "day": 2 },
              "nightlyTemperatureCelsius": 50
            }
        } ] }
        """#.utf8)
        XCTAssertNil(try GoogleHealthSkinTempMapper.mapListResponse(cold))
        XCTAssertNil(try GoogleHealthSkinTempMapper.mapListResponse(hot))
    }

    func testCivilRankOrdering() {
        let earlier = GoogleHealthSkinTempMapper.CivilDate(year: 2026, month: 9, day: 29)
        let later = GoogleHealthSkinTempMapper.CivilDate(year: 2026, month: 9, day: 30)
        XCTAssertLessThan(
            GoogleHealthSkinTempMapper.civilRank(earlier),
            GoogleHealthSkinTempMapper.civilRank(later)
        )
    }
}
