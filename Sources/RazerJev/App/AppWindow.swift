import AppKit

@MainActor
final class AppWindow: NSObject, NSApplicationDelegate {
    private static let width: CGFloat = 460
    private static let rowHeight: CGFloat = 52
    private static let visibleRows: CGFloat = 3.5
    private static let modeFills = [Paint.yellow, Paint.cyan, Paint.magenta, Paint.orange, Paint.green]

    private let light: Light
    private let canvas = PaintCanvas()
    private let modeList = FlippedView()
    private let status = PaintLabel("pick a colour or a mode")
    private var modes: [WatchMode] = []
    private var modeButtons: [PaintButton] = []
    private var chosenModeID: String?
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
        let scroll = NSScrollView(frame: CGRect(x: 20, y: 196, width: Self.width - 40, height: Self.rowHeight * Self.visibleRows))
        scroll.hasVerticalScroller = true
        scroll.drawsBackground = false
        scroll.documentView = modeList
        canvas.addSubview(scroll)

        let addYourOwn = PaintButton(title: "+ add ur own mode", fill: Paint.white, tilt: -2,
                                     target: self, action: #selector(openModesFolder))
        addYourOwn.frame = CGRect(x: Self.width - 250, y: scroll.frame.maxY + 6, width: 230, height: 46)
        canvas.addSubview(addYourOwn)

        let bubbleTop = addYourOwn.frame.maxY + 14
        canvas.bubble = CGRect(x: 86, y: bubbleTop, width: Self.width - 106, height: 84)
        status.frame = canvas.bubble.insetBy(dx: 12, dy: 8)
        canvas.addSubview(status)

        canvas.frame = CGRect(x: 0, y: 0, width: Self.width, height: bubbleTop + 104)
        window.setContentSize(canvas.frame.size)
        window.title = App.name
        window.contentView = canvas
        reloadModes()
        window.center()
        window.makeKeyAndOrderFront(nil)
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        if !modeButtons.isEmpty { reloadModes() }
    }

    private func reloadModes() {
        let (loaded, problems) = ModeLibrary.load()
        if let problem = problems.first { status.text = problem }
        let unchanged = loaded.map(\.id) == modes.map(\.id) && loaded.map(\.title) == modes.map(\.title)
        modes = loaded
        if unchanged && !modeButtons.isEmpty { return }
        if let chosen = chosenModeID, !modes.contains(where: { $0.id == chosen }) { choose(nil) }

        modeButtons.forEach { $0.removeFromSuperview() }
        let titles = ["do nothing"] + modes.map(\.title)
        modeButtons = titles.enumerated().map { index, title in
            let button = PaintButton(title: title, fill: Self.modeFills[index % Self.modeFills.count],
                                     tilt: index.isMultiple(of: 2) ? 1 : -1.5, target: self, action: #selector(pickMode(_:)))
            button.tag = index
            button.frame = CGRect(x: 6 + CGFloat(index % 2) * 10, y: CGFloat(index) * Self.rowHeight,
                                  width: Self.width - 80, height: Self.rowHeight - 2)
            modeList.addSubview(button)
            return button
        }
        modeList.frame = CGRect(x: 0, y: 0, width: Self.width - 56, height: CGFloat(titles.count) * Self.rowHeight)
        markChosen()
    }

    @objc private func pickColor(_ sender: NSButton) {
        choose(nil)
        let preset = RGB.named[sender.tag]
        do {
            try light.show(preset.color)
            status.text = "Mouse is \(preset.name.lowercased())."
        } catch {
            status.text = "\(error)"
        }
    }

    @objc private func pickMode(_ sender: NSButton) {
        let mode = sender.tag == 0 ? nil : modes[sender.tag - 1]
        choose(mode)
        if let mode { watcher.start(mode) } else { status.text = "Stopped." }
    }

    @objc private func openModesFolder() {
        do {
            NSWorkspace.shared.open(try ModeLibrary.openYourFolder())
            status.text = "Drop a .json mode in this folder (copy my-mode.json.example), then come back here."
        } catch {
            status.text = "\(error)"
        }
    }

    private func choose(_ mode: WatchMode?) {
        if mode == nil { watcher.stop(quietly: true) }
        chosenModeID = mode?.id
        markChosen()
    }

    private func markChosen() {
        let chosenIndex = chosenModeID.flatMap { id in modes.firstIndex { $0.id == id } }.map { $0 + 1 } ?? 0
        for button in modeButtons { button.isChosen = button.tag == chosenIndex }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

final class FlippedView: NSView {
    override var isFlipped: Bool { true }
}
