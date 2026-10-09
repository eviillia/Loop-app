import Foundation
import SwiftData
import Combine

@MainActor
class CounterViewModel: ObservableObject {
    @Published var currentRow: Int = 0
    @Published var timerSeconds: TimeInterval = 0
    @Published var isTimerRunning = false

    private var pattern: Pattern?
    private var timer: AnyCancellable?
    private var startDate: Date?
    private var context: ModelContext?

    var maxRow: Int? {
        guard let pattern else { return nil }
        switch pattern.type {
        case .circularEditor:
            return pattern.numberOfRings
        case .gridEditor:
            return pattern.gridHeight
        case .textEditor:
            guard let text = pattern.textPattern else { return nil }
            let lines = text.components(separatedBy: "\n")
                .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            return lines.count
        default:
            return nil
        }
    }

    func setup(for pattern: Pattern, context: ModelContext) {
        self.pattern = pattern
        self.context = context
        currentRow = pattern.currentRow
        timerSeconds = pattern.timerSeconds
        startTimer()
    }

    func incrementRow() {
        if let max = maxRow, currentRow >= max - 1 { return }
        currentRow += 1
        pattern?.currentRow = currentRow
        save()
    }

    func decrementRow() {
        guard currentRow > 0 else { return }
        currentRow -= 1
        pattern?.currentRow = currentRow
        save()
    }

    func startTimer() {
        guard !isTimerRunning else { return }
        isTimerRunning = true
        startDate = Date()
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self, let start = self.startDate else { return }
                self.timerSeconds = Date().timeIntervalSince(start)
                self.pattern?.timerSeconds = self.timerSeconds
            }
    }

    func stopTimer() {
        isTimerRunning = false
        timer?.cancel()
        timer = nil
        if let project = pattern?.project {
            project.totalTime += timerSeconds
        }
        save()
    }

    private func save() {
        try? context?.save()
    }
}
