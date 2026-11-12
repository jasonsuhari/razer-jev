import AppKit

final class PaintCanvas: NSView {
    var bubble: CGRect = .zero { didSet { needsDisplay = true } }
    var promptAt: CGPoint = .zero

    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        var doodle = Doodle(seed: "canvas")
        Paint.pixelated(bounds) {
            Paint.white.setFill()
            bounds.fill()

            for (index, letter) in "razer jev!!1".enumerated() {
                Paint.text(String(letter), at: CGPoint(x: 22 + CGFloat(index) * 21 + 3, y: 22 + CGFloat(index) * 1.2 + 3),
                           size: 34, color: Paint.black, degrees: -4, bold: true)
                Paint.text(String(letter), at: CGPoint(x: 22 + CGFloat(index) * 21, y: 22 + CGFloat(index) * 1.2),
                           size: 34, color: Paint.rainbow[index % Paint.rainbow.count], degrees: -4 + doodle.wobble(5), bold: true)
            }

            let sun = CGPoint(x: bounds.maxX - 50, y: 44)
            Paint.yellow.setFill()
            NSBezierPath(ovalIn: CGRect(x: sun.x - 20, y: sun.y - 20, width: 40, height: 40)).fill()
            Paint.orange.setStroke()
            for ray in 0..<9 {
                let angle = CGFloat(ray) / 9 * 2 * .pi + doodle.wobble(0.2)
                let path = doodle.shaky([CGPoint(x: sun.x + cos(angle) * 26, y: sun.y + sin(angle) * 26),
                                         CGPoint(x: sun.x + cos(angle) * (40 + doodle.wobble(6)),
                                                 y: sun.y + sin(angle) * (40 + doodle.wobble(6)))], wobble: 1.5, steps: 3)
                path.lineWidth = 3
                path.stroke()
            }
            Paint.text("^ ^", at: CGPoint(x: sun.x - 11, y: sun.y - 14), size: 14, color: Paint.black)
            Paint.text("u", at: CGPoint(x: sun.x - 5, y: sun.y - 4), size: 14, color: Paint.black)

            doodle.spray(around: CGPoint(x: 30, y: bounds.maxY - 120), radius: 26, dots: 90, color: Paint.magenta)
            doodle.spray(around: CGPoint(x: bounds.maxX - 30, y: 150), radius: 22, dots: 70, color: Paint.cyan)

            Paint.text("pick a mode >:)", at: promptAt, size: 19, color: Paint.blue, degrees: 2)
            Paint.red.setStroke()
            let underline = doodle.shaky([CGPoint(x: promptAt.x, y: promptAt.y + 28),
                                          CGPoint(x: promptAt.x + 140, y: promptAt.y + 32)], wobble: 2, steps: 8)
            underline.lineWidth = 2
            underline.stroke()

            drawStickFigure(at: CGPoint(x: 38, y: bubble.midY - 10), doodle: &doodle)
            Paint.white.setFill()
            Paint.black.setStroke()
            let speech = doodle.box(bubble, wobble: 2)
            speech.fill()
            speech.lineWidth = 2
            speech.stroke()
            let tail = doodle.shaky([CGPoint(x: bubble.minX + 2, y: bubble.midY - 6), CGPoint(x: bubble.minX - 16, y: bubble.midY + 4),
                                     CGPoint(x: bubble.minX + 2, y: bubble.midY + 8)], wobble: 1, steps: 2)
            tail.lineWidth = 2
            tail.stroke()
        }
    }

    private func drawStickFigure(at head: CGPoint, doodle: inout Doodle) {
        Paint.black.setStroke()
        let face = NSBezierPath(ovalIn: CGRect(x: head.x - 11, y: head.y - 11, width: 22, height: 22))
        face.lineWidth = 2
        face.stroke()
        Paint.black.setFill()
        CGRect(x: head.x - 5, y: head.y - 4, width: 3, height: 3).fill()
        CGRect(x: head.x + 2, y: head.y - 4, width: 3, height: 3).fill()
        let smile = doodle.shaky([CGPoint(x: head.x - 6, y: head.y + 3), CGPoint(x: head.x, y: head.y + 7),
                                  CGPoint(x: head.x + 6, y: head.y + 2)], wobble: 0.5, steps: 2)
        smile.lineWidth = 1.5
        smile.stroke()
        let limbs: [[CGPoint]] = [
            [CGPoint(x: head.x, y: head.y + 11), CGPoint(x: head.x + 1, y: head.y + 40)],
            [CGPoint(x: head.x - 16, y: head.y + 18), CGPoint(x: head.x, y: head.y + 24), CGPoint(x: head.x + 18, y: head.y + 14)],
            [CGPoint(x: head.x - 12, y: head.y + 58), CGPoint(x: head.x + 1, y: head.y + 40), CGPoint(x: head.x + 13, y: head.y + 58)],
        ]
        for limb in limbs {
            let path = doodle.shaky(limb, wobble: 1, steps: 3)
            path.lineWidth = 2
            path.stroke()
        }
    }
}
