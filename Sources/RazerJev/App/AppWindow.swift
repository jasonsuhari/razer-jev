import AppKit

@MainActor
final class AppWindow: NSObject, NSApplicationDelegate {
    private static let width: CGFloat = 460
    private static let modeFills = [Paint.yellow, Paint.cyan, Paint.magenta, Paint.orange]

    private let light: Light
    private let canvas = PaintCanvas()
    private let status = PaintLabel("pick a colour or a mode")
    private var modeButtons: [PaintButton] = []
    private lazy var watcher = Watcher(light: light) { [weak self] message in self?.status.text = message }
    private lazy var window = NSWindow(contentRect: .zero, styleMask: [.titled, .closable, .miniaturizable],
                                       backing: .buffered, defer: false)

    init(light: Light) { self.light = light }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let colorWidth = (Self.width - 40) / CGFloat(RGB.named.count)
        for (index, preset) in RGB.named.enumerated() {
            let button = PaintButton(title: preset.name.uppercased(), fill: Paint.color(for: preset.color),
                                     labelColor: preset.color == .off ? Paint.white : Paint.black,
                                     tilt: index.isMultiple(of: 2) ? -3 : 2, target: self, action: #selector(pickColor(_:)))
            button.tag = index
            button.frame = CGRect(x: 20 + CGFloat(index) * colorWidth, y: 84, width: colorWidth, height: 64)
            canvas.addSubview(button)
        }

        canvas.promptAt = CGPoint(x: 28, y: 160)
        let titles = ["do nothing"] + WatchMode.all.map(\.title)
        for (index, title) in titles.enumerated() {
            let button = PaintButton(title: title, fill: Self.modeFills[index % Self.modeFills.count],
                                     tilt: index.isMultiple(of: 2) ? 1 : -1.5, target: self, action: #selector(pickMode(_:)))
            button.tag = index
            button.frame = CGRect(x: 36 + CGFloat(index % 2) * 10, y: 200 + CGFloat(index) * 52, width: Self.width - 80, height: 50)
            canvas.addSubview(button)
            modeButtons.append(button)
        }
        modeButtons.first?.isChosen = true

        let bubbleTop = 200 + CGFloat(titles.count) * 52 + 20
        canvas.bubble = CGRect(x: 86, y: bubbleTop, width: Self.width - 106, height: 84)
        status.frame = canvas.bubble.insetBy(dx: 12, dy: 8)
        canvas.addSubview(status)

        let height = bubbleTop + 84 + 20
        canvas.frame = CGRect(x: 0, y: 0, width: Self.width, height: height)
        window.setContentSize(canvas.frame.size)
        window.title = App.name
        window.contentView = canvas
        window.center()
        window.makeKeyAndOrderFront(nil)
    }

    @objc private func pickColor(_ sender: NSButton) {
        choose(mode: 0)
        let preset = RGB.named[sender.tag]
        do {
            try light.show(preset.color)
            status.text = "Mouse is \(preset.name.lowercased())."
        } catch {
            status.text = "\(error)"
        }
    }

    @objc private func pickMode(_ sender: NSButton) {
        choose(mode: sender.tag)
        sender.tag == 0 ? watcher.stop() : watcher.start(WatchMode.all[sender.tag - 1])
    }

    private func choose(mode index: Int) {
        if index == 0 { watcher.stop(quietly: true) }
        for button in modeButtons { button.isChosen = button.tag == index }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}
