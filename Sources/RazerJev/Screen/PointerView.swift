import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

struct PointerView {
    let image: CGImage
    let pointer: CGPoint
    let pixelsPerPoint: CGFloat

    static let ringRadiusInPoints: CGFloat = 16
    static let jevLongestSide: CGFloat = 1568
    static let jevShortestSide: CGFloat = 280

    func markedPNG() -> Data? {
        let longest = CGFloat(max(image.width, image.height)), shortest = CGFloat(min(image.width, image.height))
        let scale = min(Self.jevLongestSide / longest, max(1, Self.jevShortestSide / shortest))
        let width = Int((CGFloat(image.width) * scale).rounded())
        let height = Int((CGFloat(image.height) * scale).rounded())
        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                                      space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
        else { return nil }
        context.interpolationQuality = .high
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        let center = CGPoint(x: pointer.x * scale, y: CGFloat(height) - pointer.y * scale)
        let radius = Self.ringRadiusInPoints * pixelsPerPoint * scale
        context.setLineWidth(max(3, radius / 6))
        context.setStrokeColor(red: 1, green: 0, blue: 1, alpha: 1)
        context.strokeEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
        guard let marked = context.makeImage() else { return nil }
        let out = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(out, UTType.png.identifier as CFString, 1, nil) else { return nil }
        CGImageDestinationAddImage(destination, marked, nil)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return out as Data
    }

    func fingerprint() -> [UInt8] {
        let side = 16
        var pixels = [UInt8](repeating: 0, count: side * side)
        pixels.withUnsafeMutableBytes { buffer in
            guard let context = CGContext(data: buffer.baseAddress, width: side, height: side, bitsPerComponent: 8,
                                          bytesPerRow: side, space: CGColorSpaceCreateDeviceGray(),
                                          bitmapInfo: CGImageAlphaInfo.none.rawValue) else { return }
            context.interpolationQuality = .medium
            context.draw(image, in: CGRect(x: 0, y: 0, width: side, height: side))
        }
        return pixels
    }

    static func difference(_ a: [UInt8], _ b: [UInt8]) -> Double {
        guard a.count == b.count, !a.isEmpty else { return .infinity }
        return Double(zip(a, b).reduce(0) { $0 + abs(Int($1.0) - Int($1.1)) }) / Double(a.count)
    }

    static func from(screenshot image: CGImage, pointer: CGPoint, pixelsPerPoint: CGFloat, scope: CaptureScope) -> PointerView? {
        guard case .aroundPointer(let points) = scope else {
            return PointerView(image: image, pointer: pointer, pixelsPerPoint: pixelsPerPoint)
        }
        let side = Int(CGFloat(points) * pixelsPerPoint)
        let x = min(max(Int(pointer.x) - side / 2, 0), max(image.width - side, 0))
        let y = min(max(Int(pointer.y) - side / 2, 0), max(image.height - side, 0))
        guard let crop = image.cropping(to: CGRect(x: x, y: y, width: min(side, image.width), height: min(side, image.height)))
        else { return nil }
        return PointerView(image: crop, pointer: CGPoint(x: pointer.x - CGFloat(x), y: pointer.y - CGFloat(y)),
                           pixelsPerPoint: pixelsPerPoint)
    }
}
