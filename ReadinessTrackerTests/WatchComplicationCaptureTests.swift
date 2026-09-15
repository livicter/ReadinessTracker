import XCTest
import SwiftUI
import UIKit
@testable import Readiness

/// Optional ImageRenderer capture for `.audit/verify-watch-complication.png`.
/// `Scripts/capture-watch-complication.sh` drops a sentinel at `/tmp/rt-audit/CAPTURE_WATCH_COMPLICATION`.
final class WatchComplicationCaptureTests: XCTestCase {
    private static let sentinelPath = "/tmp/rt-audit/CAPTURE_WATCH_COMPLICATION"
    private static let defaultPNGPath = "/tmp/rt-audit/verify-watch-complication.png"

    @MainActor
    func testCaptureWatchComplicationPNGWhenRequested() throws {
        let env = ProcessInfo.processInfo.environment
        let sentinelOK = FileManager.default.fileExists(atPath: Self.sentinelPath)
            || env["CAPTURE_WATCH_COMPLICATION"] == "1"
        guard sentinelOK else {
            throw XCTSkip("Drop \(Self.sentinelPath) or set CAPTURE_WATCH_COMPLICATION=1 to render audit PNG")
        }

        let path = env["WATCH_COMPLICATION_PNG_PATH"] ?? Self.defaultPNGPath

        let view = WatchComplicationChrome(gymScore: 82, workScore: 75, sleepScore: 80)
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
        XCTAssertGreaterThan(size?.intValue ?? 0, 800)

        let attachment = XCTAttachment(image: image)
        attachment.name = "verify-watch-complication.png"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testCaptureWatchComplicationRectangularPNGWhenRequested() throws {
        let env = ProcessInfo.processInfo.environment
        let sentinelPath = "/tmp/rt-audit/CAPTURE_WATCH_COMPLICATION_RECTANGULAR"
        let sentinelOK = FileManager.default.fileExists(atPath: sentinelPath)
            || env["CAPTURE_WATCH_COMPLICATION_RECTANGULAR"] == "1"
        guard sentinelOK else {
            throw XCTSkip("Drop \(sentinelPath) or set CAPTURE_WATCH_COMPLICATION_RECTANGULAR=1 to render audit PNG")
        }

        let path = env["WATCH_COMPLICATION_RECTANGULAR_PNG_PATH"] ?? "/tmp/rt-audit/verify-watch-complication-rectangular.png"

        let view = WatchComplicationRectangularChrome(
            gymScore: 82,
            workScore: 75,
            sleepScore: 80,
            readinessScore: 79
        )
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
        XCTAssertGreaterThan(size?.intValue ?? 0, 800)

        let attachment = XCTAttachment(image: image)
        attachment.name = "verify-watch-complication-rectangular.png"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testCaptureWatchComplicationInlinePNGWhenRequested() throws {
        let env = ProcessInfo.processInfo.environment
        let sentinelPath = "/tmp/rt-audit/CAPTURE_WATCH_COMPLICATION_INLINE"
        let sentinelOK = FileManager.default.fileExists(atPath: sentinelPath)
            || env["CAPTURE_WATCH_COMPLICATION_INLINE"] == "1"
        guard sentinelOK else {
            throw XCTSkip("Drop \(sentinelPath) or set CAPTURE_WATCH_COMPLICATION_INLINE=1 to render audit PNG")
        }

        let path = env["WATCH_COMPLICATION_INLINE_PNG_PATH"] ?? "/tmp/rt-audit/verify-watch-complication-inline.png"

        let view = WatchComplicationInlineChrome(
            gymScore: 82,
            workScore: 75,
            sleepScore: 80,
            readinessScore: 79
        )
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
        XCTAssertGreaterThan(size?.intValue ?? 0, 800)

        let attachment = XCTAttachment(image: image)
        attachment.name = "verify-watch-complication-inline.png"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
