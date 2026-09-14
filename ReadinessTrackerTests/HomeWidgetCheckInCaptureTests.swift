import XCTest
import SwiftUI
import UIKit
@testable import Readiness

/// Optional ImageRenderer capture for `.audit/verify-home-widget-checkin.png`.
/// `Scripts/capture-home-widget-checkin.sh` drops a sentinel at `/tmp/rt-audit/CAPTURE_HOME_WIDGET_CHECKIN`.
final class HomeWidgetCheckInCaptureTests: XCTestCase {
    private static let sentinelPath = "/tmp/rt-audit/CAPTURE_HOME_WIDGET_CHECKIN"
    private static let defaultPNGPath = "/tmp/rt-audit/verify-home-widget-checkin.png"

    @MainActor
    func testCaptureHomeWidgetCheckInPNGWhenRequested() throws {
        let env = ProcessInfo.processInfo.environment
        let sentinelOK = FileManager.default.fileExists(atPath: Self.sentinelPath)
            || env["CAPTURE_HOME_WIDGET_CHECKIN"] == "1"
        guard sentinelOK else {
            throw XCTSkip("Drop \(Self.sentinelPath) or set CAPTURE_HOME_WIDGET_CHECKIN=1 to render audit PNG")
        }

        let path = env["HOME_WIDGET_CHECKIN_PNG_PATH"] ?? Self.defaultPNGPath

        let view = HomeWidgetCheckInChrome(gymScore: 82, workScore: 75, sleepScore: 80)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 3
        guard let image = renderer.uiImage, let data = image.pngData() else {
            XCTFail("ImageRenderer failed")
            return
        }
        let url = URL(fileURLWithPath: path)
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try data.write(to: url)
        XCTAssertTrue(FileManager.default.fileExists(atPath: path), path)
        let attrs = try FileManager.default.attributesOfItem(atPath: path)
        let size = attrs[.size] as? NSNumber
        XCTAssertGreaterThan(size?.intValue ?? 0, 1000)

        let attachment = XCTAttachment(image: image)
        attachment.name = "verify-home-widget-checkin.png"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
