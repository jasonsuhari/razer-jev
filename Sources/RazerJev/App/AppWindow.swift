import AppKit

@MainActor
final class AppWindow: NSObject, NSApplicationDelegate {
    private let light: Light
    private let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 340, height: 170),
                                  styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
    private let modeMenu = NSPopUpButton(frame: .zero, pullsDown: false)
    private let status = NSTextField(wrappingLabelWithString: "Pick a colour or a mode.")
    private lazy var watcher = Watcher(light: light) { [weak self] message in self?.status.stringValue = message }

    init(light: Light) { self.light = light }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let buttons = RGB.named.enumerated().map { index, preset in
            let button = NSButton(title: preset.name, target: self, action: #selector(pickColor(_:)))
            button.tag = index
            button.bezelColor = NSColor(red: CGFloat(preset.color.red) / 255, green: CGFloat(preset.color.green) / 255,
                                        blue: CGFloat(preset.color.blue) / 255, alpha: 1)
            button.controlSize = .large
            return button
        }
        let colorRow = NSStackView(views: buttons)
        colorRow.distribution = .fillEqually
        modeMenu.addItems(withTitles: ["Watch: off"] + WatchMode.all.map(\.title))
        modeMenu.target = self
        modeMenu.action = #selector(pickMode(_:))
        status.textColor = .secondaryLabelColor
        status.preferredMaxLayoutWidth = 292

        let column = NSStackView(views: [colorRow, modeMenu, status])
        column.orientation = .vertical
        column.alignment = .leading
        column.spacing = 14
        column.edgeInsets = NSEdgeInsets(top: 24, left: 24, bottom: 20, right: 24)
        window.title = App.name
        window.contentView = column
        window.center()
        window.makeKeyAndOrderFront(nil)
    }

    @objc private func pickColor(_ sender: NSButton) {
        watcher.stop(quietly: true)
        modeMenu.selectItem(at: 0)
        let preset = RGB.named[sender.tag]
        do {
            try light.show(preset.color)
            status.stringValue = "Mouse is \(preset.name.lowercased())."
        } catch {
            status.stringValue = "\(error)"
        }
    }

    @objc private func pickMode(_ sender: NSPopUpButton) {
        let index = sender.indexOfSelectedItem - 1
        index >= 0 ? watcher.start(WatchMode.all[index]) : watcher.stop()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}
