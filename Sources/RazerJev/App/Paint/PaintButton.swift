import AppKit

final class PaintButton: NSButton {
    var fill: NSColor
    var labelColor: NSColor
    var tilt: CGFloat
    var isChosen = false { didSet { needsDisplay = true } }

    init(title: String, fill: NSColor, labelColor: NSColor = Paint.black, tilt: CGFloat, target: AnyObject, action: Selector) {
        self.fill = fill
        self.labelColor = labelColor
        self.tilt = tilt
        super.init(frame: .zero)
        self.title = title
        self.target = target
        self.action = action
        isBordered = false
        focusRingType = .none
    }

    required init?(coder: NSCoder) { nil }

    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        var doodle = Doodle(seed: title)
        let box = bounds.insetBy(dx: 12, dy: 8)
        Paint.pixelated(bounds) {
            doodle.bucketFill(box, with: isHighlighted ? Paint.white : fill)
            Paint.black.setStroke()
            let outline = doodle.box(box, wobble: 1.5)
            outline.lineWidth = 3
            outline.stroke()
            let size = Paint.fittingSize(title, width: box.width - 20, upTo: box.height > 44 ? 22 : 17)
            let width = (title as NSString).size(withAttributes: [.font: Paint.font(size, bold: true)]).width
            Paint.text(title, at: CGPoint(x: box.midX - width / 2, y: box.midY - size * 0.75),
                       size: size, color: labelColor, degrees: tilt, bold: true)
            if isChosen {
                Paint.red.setStroke()
                let circle = doodle.loop(around: box, wobble: 3)
                circle.lineWidth = 4
                circle.stroke()
            }
        }
    }
}
