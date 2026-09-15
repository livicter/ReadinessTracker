import XCTest
import SwiftUI
import UIKit
@testable import Readiness

/// Optional ImageRenderer captures for Lock Screen accessory PNGs.
/// Circular: `Scripts/capture-lock-widget.sh` → `/tmp/rt-audit/CAPTURE_LOCK_WIDGET`.
/// Rectangular: `Scripts/capture-lock-widget-rectangular.sh` → `/tmp/rt-audit/CAPTURE_LOCK_WIDGET_RECTANGULAR`.
/// Inline: `Scripts/capture-lock-widget-inline.sh` → `/tmp/rt-audit/CAPTURE_LOCK_WIDGET_INLINE`.
final class LockWidgetCaptureTests: XCTestCase {
    private static let sentinelPath = "/tmp/rt-audit/CAPTURE_LOCK_WIDGET"
    private static let defaultPNGPath = "/tmp/rt-audit/verify-lock-widget.png"

    @MainActor
    func testCaptureLockWidgetPNGWhenRequested() throws {
        let env = ProcessInfo.processInfo.environment
        let sentinelOK = FileManager.default.fileExists(atPath: Self.sentinelPath)
            || env["CAPTURE_LOCK_WIDGET"] == "1"
        guard sentinelOK else {
            throw XCTSkip("Drop \(Self.sentinelPath) or set CAPTURE_LOCK_WIDGET=1 to render audit PNG")
        }

        let path = env["LOCK_WIDGET_PNG_PATH"] ?? Self.defaultPNGPath

        let view = LockScreenAccessoryChrome(gymScore: 82, workScore: 75, sleepScore: 80)
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
        attachment.name = "verify-lock-widget.png"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testCaptureLockWidgetRectangularPNGWhenRequested() throws {
        let env = ProcessInfo.processInfo.environment
        let sentinelPath = "/tmp/rt-audit/CAPTURE_LOCK_WIDGET_RECTANGULAR"
        let sentinelOK = FileManager.default.fileExists(atPath: sentinelPath)
            || env["CAPTURE_LOCK_WIDGET_RECTANGULAR"] == "1"
        guard sentinelOK else {
            throw XCTSkip("Drop \(sentinelPath) or set CAPTURE_LOCK_WIDGET_RECTANGULAR=1 to render audit PNG")
        }

        let path = env["LOCK_WIDGET_RECTANGULAR_PNG_PATH"] ?? "/tmp/rt-audit/verify-lock-widget-rectangular.png"

        let view = LockScreenRectangularChrome(gymScore: 82, workScore: 75, sleepScore: 80, readinessScore: 78)
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
        attachment.name = "verify-lock-widget-rectangular.png"
        attachment.lifetime = .keepAlways
        add(attachment)
    }


    @MainActor
    func testCaptureLockWidgetInlinePNGWhenRequested() throws {
        let env = ProcessInfo.processInfo.environment
        let sentinelPath = "/tmp/rt-audit/CAPTURE_LOCK_WIDGET_INLINE"
        let sentinelOK = FileManager.default.fileExists(atPath: sentinelPath)
            || env["CAPTURE_LOCK_WIDGET_INLINE"] == "1"
        guard sentinelOK else {
            throw XCTSkip("Drop \(sentinelPath) or set CAPTURE_LOCK_WIDGET_INLINE=1 to render audit PNG")
        }

        let path = env["LOCK_WIDGET_INLINE_PNG_PATH"] ?? "/tmp/rt-audit/verify-lock-widget-inline.png"

        let view = LockScreenInlineChrome(gymScore: 82, workScore: 75, sleepScore: 80, readinessScore: 78)
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
        attachment.name = "verify-lock-widget-inline.png"
        attachment.lifetime = .keepAlways
        add(attachment)
    }


}
