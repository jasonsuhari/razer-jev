import AppKit

enum Paint {
    static let red = NSColor(srgbRed: 1, green: 0, blue: 0, alpha: 1)
    static let green = NSColor(srgbRed: 0, green: 1, blue: 0, alpha: 1)
    static let blue = NSColor(srgbRed: 0, green: 0, blue: 1, alpha: 1)
    static let yellow = NSColor(srgbRed: 1, green: 1, blue: 0, alpha: 1)
    static let cyan = NSColor(srgbRed: 0, green: 1, blue: 1, alpha: 1)
    static let magenta = NSColor(srgbRed: 1, green: 0, blue: 1, alpha: 1)
    static let orange = NSColor(srgbRed: 1, green: 0.5, blue: 0, alpha: 1)
    static let black = NSColor.black
    static let white = NSColor.white
    static let rainbow = [red, orange, yellow, green, cyan, blue, magenta]

    static func font(_ size: CGFloat, bold: Bool = false) -> NSFont {
        NSFont(name: bold ? "Comic Sans MS Bold" : "Comic Sans MS", size: size) ?? .systemFont(ofSize: size)
    }

    static func color(for light: RGB) -> NSColor {
        NSColor(srgbRed: CGFloat(light.red) / 255, green: CGFloat(light.green) / 255,
                blue: CGFloat(light.blue) / 255, alpha: 1)
    }

    static func pixelated(_ bounds: CGRect, _ draw: () -> Void) {
        guard let canvas = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(bounds.width), pixelsHigh: Int(bounds.height),
                                            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                                            colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0),
              let pixels = NSGraphicsContext(bitmapImageRep: canvas),
              let screen = NSGraphicsContext.current
        else { return draw() }
        let paint = NSGraphicsContext(cgContext: pixels.cgContext, flipped: true)
        paint.cgContext.translateBy(x: 0, y: bounds.height)
        paint.cgContext.scaleBy(x: 1, y: -1)
        paint.shouldAntialias = false
        paint.cgContext.setShouldSmoothFonts(false)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = paint
        draw()
        NSGraphicsContext.restoreGraphicsState()
        screen.imageInterpolation = .none
        canvas.draw(in: bounds, from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)
    }

    static func fittingSize(_ text: String, width: CGFloat, upTo size: CGFloat) -> CGFloat {
        let natural = (text as NSString).size(withAttributes: [.font: font(size, bold: true)]).width
        return natural <= width ? size : max(10, (size * width / natural).rounded(.down))
    }

    static func text(_ string: String, at point: CGPoint, size: CGFloat, color: NSColor,
                     degrees: CGFloat = 0, bold: Bool = false) {
        let attributes: [NSAttributedString.Key: Any] = [.font: font(size, bold: bold), .foregroundColor: color]
        NSGraphicsContext.saveGraphicsState()
        let turn = NSAffineTransform()
        turn.translateX(by: point.x, yBy: point.y)
        turn.rotate(byDegrees: degrees)
        turn.concat()
        string.draw(at: .zero, withAttributes: attributes)
        NSGraphicsContext.restoreGraphicsState()
    }
}

struct Doodle {
    private var state: UInt64

    init(seed: String) {
        state = seed.utf8.reduce(1469598103934665603) { ($0 ^ UInt64($1)) &* 1099511628211 }
    }

    mutating func wobble(_ amount: CGFloat) -> CGFloat {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return (CGFloat(state >> 33) / CGFloat(UInt32.max >> 1) - 0.5) * 2 * amount
    }

    mutating func shaky(_ points: [CGPoint], wobble amount: CGFloat, steps: Int = 6) -> NSBezierPath {
        let path = NSBezierPath()
        path.lineJoinStyle = .miter
        guard let first = points.first else { return path }
        path.move(to: first)
        for (start, end) in zip(points, points.dropFirst()) {
            for step in 1...steps {
                let t = CGFloat(step) / CGFloat(steps)
                let jitter = step == steps ? wobble(amount / 2) : wobble(amount)
                path.line(to: CGPoint(x: start.x + (end.x - start.x) * t + jitter,
                                      y: start.y + (end.y - start.y) * t + wobble(amount)))
            }
        }
        return path
    }

    mutating func box(_ rect: CGRect, wobble amount: CGFloat) -> NSBezierPath {
        let overshoot = CGPoint(x: rect.minX + 6 + wobble(3), y: rect.minY - 2 + wobble(2))
        return shaky([CGPoint(x: rect.minX + wobble(2), y: rect.minY + wobble(2)),
                      CGPoint(x: rect.maxX + wobble(3), y: rect.minY + wobble(3)),
                      CGPoint(x: rect.maxX + wobble(3), y: rect.maxY + wobble(3)),
                      CGPoint(x: rect.minX + wobble(3), y: rect.maxY + wobble(3)),
                      CGPoint(x: rect.minX + wobble(2), y: rect.minY + wobble(2)), overshoot],
                     wobble: amount)
    }

    mutating func loop(around rect: CGRect, wobble amount: CGFloat) -> NSBezierPath {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let steps = 40
        let points = (0...steps + 6).map { step -> CGPoint in
            let angle = CGFloat(step) / CGFloat(steps) * 2 * .pi
            return CGPoint(x: center.x + cos(angle) * (rect.width / 2 + 10 + wobble(amount)),
                           y: center.y + sin(angle) * (rect.height / 2 + 8 + wobble(amount)))
        }
        return shaky(points, wobble: 0, steps: 1)
    }

    mutating func bucketFill(_ rect: CGRect, with color: NSColor) {
        color.setFill()
        let missed = CGRect(x: rect.minX + 2 + abs(wobble(3)), y: rect.minY + 2 + abs(wobble(3)),
                            width: rect.width - 5 - abs(wobble(4)), height: rect.height - 5 - abs(wobble(4)))
        shaky([missed.origin, CGPoint(x: missed.maxX, y: missed.minY), CGPoint(x: missed.maxX, y: missed.maxY),
               CGPoint(x: missed.minX, y: missed.maxY)], wobble: 1.5).fill()
    }

    mutating func spray(around center: CGPoint, radius: CGFloat, dots: Int, color: NSColor) {
        color.setFill()
        for _ in 0..<dots {
            let angle = wobble(.pi), distance = abs(wobble(radius))
            CGRect(x: center.x + cos(angle) * distance, y: center.y + sin(angle) * distance, width: 1.5, height: 1.5).fill()
        }
    }
}
