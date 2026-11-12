import Foundation

enum CaptureScope {
    case aroundPointer(points: Double)
    case windowUnderPointer
}

struct WatchMode {
    struct Answer {
        let id: String
        let meaning: String
        let light: RGB
    }

    let id: String
    let title: String
    let scope: CaptureScope
    let question: String
    let answers: [Answer]

    var criteria: [String: String] {
        Dictionary(uniqueKeysWithValues: answers.map { ($0.id, $0.meaning) })
    }

    func light(for answerID: String) -> RGB? {
        answers.first { $0.id == answerID }?.light
    }
}

extension WatchMode {
    private struct File: Decodable {
        struct Answer: Decodable { let id: String; let means: String; let light: String }
        let title: String
        let look_at: String
        let question: String
        let answers: [Answer]
    }

    struct FileError: Error, CustomStringConvertible {
        let description: String
    }

    init(contentsOf url: URL) throws {
        let file: File
        do { file = try JSONDecoder().decode(File.self, from: Data(contentsOf: url)) } catch {
            throw FileError(description: "\(url.lastPathComponent): not valid mode JSON (\(error.localizedDescription))")
        }
        guard file.answers.count >= 2 else { throw FileError(description: "\(url.lastPathComponent): needs at least two answers") }
        let scope: CaptureScope
        switch file.look_at {
        case "pointer": scope = .aroundPointer(points: 320)
        case "window": scope = .windowUnderPointer
        default: throw FileError(description: "\(url.lastPathComponent): look_at must be \"pointer\" or \"window\"")
        }
        let answers = try file.answers.map { answer in
            guard let light = RGB(answer.light) else {
                throw FileError(description: "\(url.lastPathComponent): \"\(answer.light)\" isn't a colour name or #rrggbb")
            }
            return Answer(id: answer.id, meaning: answer.means, light: light)
        }
        self.init(id: url.deletingPathExtension().lastPathComponent, title: file.title, scope: scope,
                  question: file.question, answers: answers)
    }
}
