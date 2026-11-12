extension WatchMode {
    static let quiz = WatchMode(
        id: "quiz",
        title: "Quiz: best answer → green, others → red",
        scope: .windowUnderPointer,
        question: "`screen` is the window under the mouse pointer. The pointer is at the centre of the magenta ring. If the window shows a question with answer options to pick from, which kind of thing is the pointer on?",
        answers: [
            Answer(id: "best", meaning: "The answer option that best answers the question shown: the one to pick.", light: .green),
            Answer(id: "other", meaning: "One of the answer options, but not the best one.", light: .red),
            Answer(id: "none", meaning: "Not an answer option: the question itself, the background, or a window with no question.", light: .off),
        ])
}
