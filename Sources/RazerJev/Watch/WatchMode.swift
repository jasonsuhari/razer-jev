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
