import AppKit

final class PaintLabel: NSView {
    var text: String { didSet { needsDisplay = true; setAccessibilityValue(text) } }

    init(_ text: String) {
        self.text = text
        super.init(frame: .zero)
        setAccessibilityElement(true)
        setAccessibilityRole(.staticText)
        setAccessibilityValue(text)
    }

    required init?(coder: NSCoder) { nil }

    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        Paint.pixelated(bounds) {
            (text as NSString).draw(in: bounds, withAttributes: [.font: Paint.font(14), .foregroundColor: Paint.blue])
        }
    }
}
