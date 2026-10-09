import SwiftUI
import PDFKit
import SwiftData

struct CounterView: View {
    @StateObject private var counterVM = CounterViewModel()
    @Environment(\.modelContext) private var modelContext
    let pattern: Pattern

    var publicPatterns: [PatternInfo]? = nil
    var publicCurrentIndex: Int? = nil

    @State private var nextPattern: Pattern? = nil
    @State private var navigateToNext = false

    private var projectPatterns: [Pattern] {
        guard let project = pattern.project else { return [] }
        return project.patterns
    }

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                ZStack {
                    Color("backgroundColor")
                    if pattern.type == .textEditor {
                        VStack(spacing: 12) {
                            Text("Ряд \(counterVM.currentRow + 1)")
                                .font(.title.weight(.bold))
                                .foregroundColor(Color("textColor"))

                            if let text = pattern.textPattern {
                                let lines = text.components(separatedBy: "\n")
                                let validLines = lines.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                                if validLines.indices.contains(counterVM.currentRow) {
                                    Text(validLines[counterVM.currentRow])
                                        .font(.title2.weight(.semibold))
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(Color("textColor"))
                                        .padding(.horizontal, 20)
                                } else {
                                    Text("Схема завершена")
                                        .font(.title3)
                                        .foregroundColor(.gray)
                                }
                            } else {
                                Text("Текст отсутствует")
                                    .font(.title3)
                                    .foregroundColor(.gray)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if pattern.type == .circularEditor {
                        CircularPatternView(pattern: pattern)
                    } else if pattern.type == .gridEditor {
                        GridPatternView(pattern: pattern)
                    } else {
                        Text("Схема не загружена")
                            .foregroundColor(.gray)
                    }
                }
                .frame(height: geo.size.height * 0.65)
                .clipped()

                VStack(spacing: 16) {
                    HStack(spacing: 0) {
                        Button(action: { counterVM.decrementRow() }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(counterVM.currentRow > 0 ? Color("textColor") : Color.gray)
                        }
                        .disabled(counterVM.currentRow == 0)

                        Spacer()

                        Text("Ряд \(counterVM.currentRow + 1)")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(Color("textColor"))

                        Spacer()

                        Button(action: { counterVM.incrementRow() }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(
                                    pattern.type == .textEditor &&
                                    counterVM.currentRow >= (counterVM.maxRow ?? 0) - 1
                                    ? Color.gray : Color("textColor")
                                )
                        }
                        .disabled(pattern.type == .textEditor && counterVM.currentRow >= (counterVM.maxRow ?? 0) - 1)
                    }
                    .padding(.horizontal)

                    HStack {
                        Text(formatTime(counterVM.timerSeconds))
                            .font(.title3)
                            .foregroundColor(Color("textColor"))
                        Spacer()
                        if counterVM.isTimerRunning {
                            Button("Стоп") { counterVM.stopTimer() }
                                .frame(width: 80)
                                .buttonStyle(PrimaryButtonStyle())
                        } else {
                            Button("Старт") { counterVM.startTimer() }
                                .frame(width: 80)
                                .buttonStyle(PrimaryButtonStyle())
                        }
                    }
                    .padding(.horizontal)

                    HStack {
                        if let publicPatterns = publicPatterns,
                           let idx = publicCurrentIndex,
                           idx < publicPatterns.count - 1 {
                            Button("След. деталь") {
                                goToNextPublicPattern()
                            }
                            .buttonStyle(PrimaryButtonStyle())
                            .frame(width: 160)
                        } else if projectPatterns.count > 1 {
                            Button("След. деталь") {
                                goToNextProjectPattern()
                            }
                            .buttonStyle(PrimaryButtonStyle())
                            .frame(width: 160)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
                .background(Color("backgroundColor"))
            }
        }
        .background(Color("backgroundColor"))
        .navigationTitle(pattern.title)
        .navigationBarTitleDisplayMode(.inline)
        .background(
            NavigationLink(destination: nextPatternView, isActive: $navigateToNext) { EmptyView() }
        )
        .onAppear {
            counterVM.setup(for: pattern, context: modelContext)
        }
        .onDisappear {
            counterVM.stopTimer()
        }
    }

    @ViewBuilder
    private var nextPatternView: some View {
        if let next = nextPattern {
            CounterView(pattern: next,
                        publicPatterns: publicPatterns,
                        publicCurrentIndex: publicCurrentIndex.map { $0 + 1 })
        }
    }

    private func goToNextProjectPattern() {
        guard !projectPatterns.isEmpty,
              let currentIndex = projectPatterns.firstIndex(where: { $0.patternID == pattern.patternID }),
              currentIndex + 1 < projectPatterns.count else { return }
        nextPattern = projectPatterns[currentIndex + 1]
        navigateToNext = true
    }

    private func goToNextPublicPattern() {
        guard let publicPatterns = publicPatterns,
              let idx = publicCurrentIndex,
              idx + 1 < publicPatterns.count else { return }
        let info = publicPatterns[idx + 1]
        let newPattern = Pattern(title: info.title, type: PatternType(rawValue: info.type) ?? .textEditor)
        newPattern.textPattern = info.textPattern
        newPattern.hookSize = info.hookSize
        newPattern.difficultyLevel = DifficultyType(rawValue: info.difficulty ?? "Нет") ?? .none
        newPattern.numberOfRings = info.numberOfRings
        newPattern.gridWidth = info.gridWidth
        newPattern.gridHeight = info.gridHeight
        if let base64 = info.graphicPatternBase64,
           let graphicData = Data(base64Encoded: base64) {
            newPattern.graphicPatternData = graphicData
        }
        modelContext.insert(newPattern)
        try? modelContext.save()
        nextPattern = newPattern
        navigateToNext = true
    }

    private func formatTime(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = Int(interval) / 60 % 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

struct PDFKitView: UIViewRepresentable {
    let url: URL
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = PDFDocument(url: url)
        pdfView.autoScales = true
        return pdfView
    }
    func updateUIView(_ uiView: PDFView, context: Context) {}
}
