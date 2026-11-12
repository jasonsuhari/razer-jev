import Foundation
import ImageIO

enum Command {
    static let usage = """
    Usage:
      RazerJev                                    open the window
      RazerJev --set red|green|off
      RazerJev --judge <mode> <screenshot> <x> <y> [--pixels-per-point 2] [--save-marked out.png]
        modes: \(WatchMode.all.map(\.id).joined(separator: ", ")); x and y are pixels in the screenshot
    """

    static func run(_ arguments: [String], light: Light) async -> Int32 {
        func value(after flag: String, _ offset: Int = 1) -> String? {
            guard let i = arguments.firstIndex(of: flag), i + offset < arguments.count else { return nil }
            return arguments[i + offset]
        }
        do {
            if let name = value(after: "--set") {
                guard let preset = RGB.named.first(where: { $0.name.lowercased() == name.lowercased() }) else { print(usage); return 2 }
                try light.show(preset.color)
                print("Mouse is \(preset.name.lowercased()).")
                return 0
            }
            if let modeID = value(after: "--judge"), let path = value(after: "--judge", 2),
               let x = value(after: "--judge", 3).flatMap(Double.init), let y = value(after: "--judge", 4).flatMap(Double.init),
               let mode = WatchMode.all.first(where: { $0.id == modeID }) {
                let pixelsPerPoint = value(after: "--pixels-per-point").flatMap(Double.init) ?? 2
                guard let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: path) as CFURL, nil),
                      let image = CGImageSourceCreateImageAtIndex(source, 0, nil),
                      let view = PointerView.from(screenshot: image, pointer: CGPoint(x: x, y: y),
                                                  pixelsPerPoint: pixelsPerPoint, scope: mode.scope),
                      let png = view.markedPNG()
                else { print("Couldn't read \(path)"); return 1 }
                if let out = value(after: "--save-marked") { try png.write(to: URL(fileURLWithPath: out)) }
                let answer = try await Jev(apiKey: APIKey.typesafe())
                    .choose(instructions: mode.question, criteria: mode.criteria, screen: png)
                let odds = mode.answers.map { "\($0.id) \(String(format: "%.2f", answer.probabilities[$0.id] ?? 0))" }
                print("\(answer.choice)  [\(odds.joined(separator: ", "))]  \(String(format: "%.2f", answer.seconds)) s")
                return 0
            }
        } catch {
            print("\(error)")
            return 1
        }
        print(usage)
        return 2
    }
}
