import Foundation

enum ModeLibrary {
    static let builtIn = Bundle.main.resourceURL?.appendingPathComponent("modes")
    static let yours = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("\(App.name)/modes")

    static func load() -> (modes: [WatchMode], problems: [String]) {
        var byID: [String: WatchMode] = [:]
        var order: [String] = []
        var problems: [String] = []
        for folder in [builtIn, yours].compactMap({ $0 }) {
            let files = (try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) ?? []
            for file in files.filter({ $0.pathExtension == "json" }).sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
                do {
                    let mode = try WatchMode(contentsOf: file)
                    if byID[mode.id] == nil { order.append(mode.id) }
                    byID[mode.id] = mode
                } catch {
                    problems.append("\(error)")
                }
            }
        }
        return (order.compactMap { byID[$0] }, problems)
    }

    static func openYourFolder() throws -> URL {
        try FileManager.default.createDirectory(at: yours, withIntermediateDirectories: true)
        let example = yours.appendingPathComponent("my-mode.json.example")
        if !FileManager.default.fileExists(atPath: example.path), let builtIn,
           let sample = try? Data(contentsOf: builtIn.appendingPathComponent("catdog.json")) {
            try sample.write(to: example)
        }
        return yours
    }
}
