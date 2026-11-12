import AppKit

let light = RazerCobra()
let arguments = Array(CommandLine.arguments.dropFirst())

if !arguments.isEmpty {
    exit(await Command.run(arguments, light: light))
}

let app = NSApplication.shared
let window = AppWindow(light: light)
app.delegate = window
app.setActivationPolicy(.regular)
app.run()
