import Foundation

@MainActor
final class Watcher {
    static let pollInterval: Duration = .milliseconds(250)
    static let stillBelow = 3.0
    static let newViewAbove = 6.0
    static let pointerStillWithin = 2.0
    static let pointerMovedBeyond = 8.0

    private let light: Light
    private let report: (String) -> Void
    private let screen = ScreenCapture()
    private var loop: Task<Void, Never>?
    private var shown: RGB?

    init(light: Light, report: @escaping (String) -> Void) {
        self.light = light
        self.report = report
    }

    func start(_ mode: WatchMode) {
        stop(quietly: true)
        guard ScreenCapture.hasPermission() else {
            report(ScreenCaptureError.needsPermission.description)
            return
        }
        loop = Task { await run(mode) }
    }

    func stop(quietly: Bool = false) {
        loop?.cancel()
        loop = nil
        shown = nil
        if !quietly { report("Stopped.") }
    }

    private func run(_ mode: WatchMode) async {
        let jev: Jev
        do { jev = Jev(apiKey: try APIKey.typesafe()) } catch {
            report("\(error)")
            return
        }
        report("Watching. Rest the pointer on something.")
        var previous: Snapshot?
        var judged: Snapshot?
        while !Task.isCancelled {
            try? await Task.sleep(for: Self.pollInterval)
            do {
                let current = try await screen.snapshot(mode.scope)
                defer { previous = current }
                guard let previous, Self.isStill(current, since: previous) else { continue }
                if let judged, !Self.isNew(current, comparedTo: judged) { continue }
                guard let png = current.view.markedPNG() else { continue }
                let answer = try await jev.choose(instructions: mode.question, criteria: mode.criteria, screen: png)
                let after = try await screen.snapshot(mode.scope)
                guard !Task.isCancelled, !Self.isNew(after, comparedTo: current) else { continue }
                judged = current
                try show(answer, for: mode)
            } catch {
                screen.forgetWindows()
                report("\(error)")
            }
        }
    }

    private func show(_ answer: ChoiceAnswer, for mode: WatchMode) throws {
        let percent = Int(((answer.probabilities[answer.choice] ?? 0) * 100).rounded())
        report("\(answer.choice.capitalized) (\(percent)%) in \(String(format: "%.2f", answer.seconds)) s")
        guard let color = mode.light(for: answer.choice), color != shown else { return }
        try light.show(color)
        shown = color
    }

    private static func isStill(_ now: Snapshot, since before: Snapshot) -> Bool {
        distance(now.pointer, before.pointer) <= pointerStillWithin
            && PointerView.difference(now.fingerprint, before.fingerprint) < stillBelow
    }

    private static func isNew(_ now: Snapshot, comparedTo before: Snapshot) -> Bool {
        distance(now.pointer, before.pointer) > pointerMovedBeyond
            || PointerView.difference(now.fingerprint, before.fingerprint) >= newViewAbove
    }

    private static func distance(_ a: CGPoint, _ b: CGPoint) -> Double {
        hypot(a.x - b.x, a.y - b.y)
    }
}
