import XCTest
@testable import Readiness

final class GoogleOAuthRedirectTests: XCTestCase {
    private let sampleClientID = "450771319977-example.apps.googleusercontent.com"
    private let sampleReversed = "com.googleusercontent.apps.450771319977-example"

    func testReversedClientIDFromStandardIOSClient() {
        XCTAssertEqual(
            GoogleOAuthRedirect.reversedClientID(from: sampleClientID),
            sampleReversed
        )
    }

    func testRedirectURIUsesOauth2RedirectPath() {
        XCTAssertEqual(
            GoogleOAuthRedirect.redirectURI(from: sampleClientID),
            "\(sampleReversed):/oauth2redirect"
        )
    }

    func testReversedClientIDRejectsMissingSuffix() {
        XCTAssertNil(GoogleOAuthRedirect.reversedClientID(from: "not-a-google-client"))
        XCTAssertNil(GoogleOAuthRedirect.redirectURI(from: ""))
    }

    func testReversedClientIDTrimsWhitespace() {
        let padded = "  \(sampleClientID)  \n"
        XCTAssertEqual(
            GoogleOAuthRedirect.reversedClientID(from: padded),
            sampleReversed
        )
    }

    func testIsCallbackURLRecognizesReverseScheme() {
        let url = URL(string: "\(sampleReversed):/oauth2redirect?code=abc")!
        XCTAssertTrue(GoogleOAuthRedirect.isCallbackURL(url))
    }

    func testIsCallbackURLRecognizesLegacyScheme() {
        let url = URL(string: "readinesstracker://oauth?code=abc")!
        XCTAssertTrue(GoogleOAuthRedirect.isCallbackURL(url))
    }

    func testIsCallbackURLRejectsUnrelated() {
        XCTAssertFalse(GoogleOAuthRedirect.isCallbackURL(URL(string: "https://example.com")!))
        XCTAssertFalse(GoogleOAuthRedirect.isCallbackURL(URL(string: "readinesstracker://checkin")!))
    }
}
