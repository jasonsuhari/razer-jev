import AppKit
import ScreenCaptureKit

struct Snapshot {
    let view: PointerView
    let fingerprint: [UInt8]
    let pointer: CGPoint
}

enum ScreenCaptureError: Error, CustomStringConvertible {
    case needsPermission, noDisplay, noWindow

    var description: String {
        switch self {
        case .needsPermission:
            return "Allow \(App.name) under System Settings > Privacy & Security > Screen & System Audio Recording, then reopen it."
        case .noDisplay: return "Couldn't find the screen the pointer is on."
        case .noWindow: return "No window under the pointer."
        }
    }
}

@MainActor
final class ScreenCapture {
    private var content: SCShareableContent?

    static func hasPermission() -> Bool {
        if CGPreflightScreenCaptureAccess() { return true }
        CGRequestScreenCaptureAccess()
        return false
    }

    func forgetWindows() { content = nil }

    func snapshot(_ scope: CaptureScope) async throws -> Snapshot {
        let mouse = NSEvent.mouseLocation
        guard let primary = NSScreen.screens.first,
              let screen = NSScreen.screens.first(where: { NSMouseInRect(mouse, $0.frame, false) })
        else { throw ScreenCaptureError.noDisplay }
        let pointer = CGPoint(x: mouse.x, y: primary.frame.maxY - mouse.y)
        let content = try await shareableContent()

        let filter: SCContentFilter
        let area: CGRect
        switch scope {
        case .aroundPointer(let points):
            guard let displayID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID,
                  let display = content.displays.first(where: { $0.displayID == displayID })
            else { throw ScreenCaptureError.noDisplay }
            let ownApp = content.applications.filter { $0.processID == ProcessInfo.processInfo.processIdentifier }
            filter = SCContentFilter(display: display, excludingApplications: ownApp, exceptingWindows: [])
            let side = CGFloat(points)
            let onDisplay = CGRect(x: min(max(pointer.x - screen.frame.minX - side / 2, 0), screen.frame.width - side),
                                   y: min(max(screen.frame.maxY - mouse.y - side / 2, 0), screen.frame.height - side),
                                   width: side, height: side)
            area = onDisplay.offsetBy(dx: screen.frame.minX, dy: primary.frame.maxY - screen.frame.maxY)
            let image = try await capture(filter, sourceRect: onDisplay, size: area.size, scale: screen.backingScaleFactor)
            return Self.snapshot(image, area: area, pointer: pointer)
        case .windowUnderPointer:
            guard let windowID = Self.frontWindowID(at: pointer) else { throw ScreenCaptureError.noWindow }
            var window = content.windows.first { $0.windowID == windowID }
            if window == nil {
                self.content = nil
                window = try await shareableContent().windows.first { $0.windowID == windowID }
            }
            guard let window else { throw ScreenCaptureError.noWindow }
            filter = SCContentFilter(desktopIndependentWindow: window)
            area = window.frame
            let image = try await capture(filter, sourceRect: nil, size: area.size, scale: screen.backingScaleFactor)
            return Self.snapshot(image, area: area, pointer: pointer)
        }
    }

    private func shareableContent() async throws -> SCShareableContent {
        if let content { return content }
        let fresh = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        content = fresh
        return fresh
    }

    private func capture(_ filter: SCContentFilter, sourceRect: CGRect?, size: CGSize, scale: CGFloat) async throws -> CGImage {
        let config = SCStreamConfiguration()
        if let sourceRect { config.sourceRect = sourceRect }
        config.width = Int(size.width * scale)
        config.height = Int(size.height * scale)
        config.showsCursor = false
        return try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
    }

    private static func snapshot(_ image: CGImage, area: CGRect, pointer: CGPoint) -> Snapshot {
        let pixelsPerPoint = CGFloat(image.width) / area.width
        let inImage = CGPoint(x: (pointer.x - area.minX) * pixelsPerPoint, y: (pointer.y - area.minY) * pixelsPerPoint)
        let view = PointerView(image: image, pointer: inImage, pixelsPerPoint: pixelsPerPoint)
        return Snapshot(view: view, fingerprint: view.fingerprint(), pointer: pointer)
    }

    private static func frontWindowID(at point: CGPoint) -> CGWindowID? {
        guard let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID)
                as? [[String: Any]] else { return nil }
        let ownPID = ProcessInfo.processInfo.processIdentifier
        return windows.lazy.compactMap { info -> CGWindowID? in
            guard (info[kCGWindowLayer as String] as? Int) == 0,
                  (info[kCGWindowOwnerPID as String] as? pid_t) != ownPID,
                  let bounds = (info[kCGWindowBounds as String] as? NSDictionary).flatMap({ CGRect(dictionaryRepresentation: $0) }),
                  bounds.contains(point)
            else { return nil }
            return info[kCGWindowNumber as String] as? CGWindowID
        }.first
    }
}
