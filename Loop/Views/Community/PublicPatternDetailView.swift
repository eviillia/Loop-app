import SwiftUI
import SwiftData

struct PublicPatternDetailView: View {
    let patternInfo: PatternInfo
    let allPatterns: [PatternInfo]
    let currentIndex: Int
    let projectTitle: String

    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var navigateToCounter = false
    @State private var createdPattern: Pattern?

    var body: some View {
        ZStack {
            Color("backgroundColor").ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(patternInfo.title)
                        .font(.title.bold())
                        .foregroundColor(Color("textColor"))

                    if let diff = patternInfo.difficulty, !diff.isEmpty {
                        Text("Сложность: \(diff)").font(.subheadline)
                    }
                    if let hook = patternInfo.hookSize {
                        Text("Крючок: \(String(format: "%.1f мм", hook))").font(.subheadline)
                    }

                    if let yarns = patternInfo.yarns, !yarns.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Пряжа").font(.headline)
                            ForEach(yarns, id: \.name) { yarn in
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(yarn.name).bold()
                                    Text("Цвет: \(yarn.color)")
                                    if let brand = yarn.brand { Text("Бренд: \(brand)") }
                                    if let material = yarn.material { Text("Состав: \(material)") }
                                }
                                .font(.caption)
                            }
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10)
                            .fill(Color("backgroundColor").opacity(0.15))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color("textColor").opacity(0.5), lineWidth: 1))
                        )
                    }

                    if patternInfo.type == "Круговой редактор" {
                        if let note = patternInfo.pinnedNote, !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Описание").font(.headline)
                                Text(note)
                                    .font(.body)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 10)
                                .fill(Color("backgroundColor").opacity(0.15))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color("textColor").opacity(0.5), lineWidth: 1))
                            )
                        }
                    } else if patternInfo.type == "Текстовый редактор" {
                        if let text = patternInfo.textPattern, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            let rows = text.components(separatedBy: "\n")
                            ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                                HStack(alignment: .top) {
                                    Text("Ряд \(index + 1):")
                                        .bold()
                                        .frame(width: 60, alignment: .leading)
                                        .foregroundColor(Color("textColor"))
                                    Text(row)
                                        .foregroundColor(Color("textColor"))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .font(.callout)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color("backgroundColor").opacity(0.5))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color("textColor").opacity(0.2), lineWidth: 1)
                                        )
                                )
                                .padding(.horizontal, 4)
                                .padding(.top, 4)
                            }
                        }
                    } else if let text = patternInfo.textPattern, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Описание").font(.headline)
                            Text(text)
                                .font(.body)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10)
                            .fill(Color("backgroundColor").opacity(0.15))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color("textColor").opacity(0.5), lineWidth: 1))
                        )
                    }

                    Button("Вязать эту схему") { startKnitting() }
                        .buttonStyle(PrimaryButtonStyle())
                }
                .padding()
            }
        }
        .navigationTitle("Схема")
        .navigationDestination(isPresented: $navigateToCounter) {
            if let pattern = createdPattern {
                CounterView(pattern: pattern,
                            publicPatterns: allPatterns,
                            publicCurrentIndex: currentIndex)
            }
        }
    }

    private func startKnitting() {
        let pattern = Pattern(title: patternInfo.title, type: PatternType(rawValue: patternInfo.type) ?? .textEditor)
        pattern.textPattern = patternInfo.textPattern
        pattern.hookSize = patternInfo.hookSize
        pattern.difficultyLevel = DifficultyType(rawValue: patternInfo.difficulty ?? "Нет") ?? .none
        pattern.numberOfRings = patternInfo.numberOfRings
        pattern.gridWidth = patternInfo.gridWidth
        pattern.gridHeight = patternInfo.gridHeight
        if let base64 = patternInfo.graphicPatternBase64,
           let graphicData = Data(base64Encoded: base64) {
            pattern.graphicPatternData = graphicData
        }
        modelContext.insert(pattern)
        pattern.user = authVM.currentUser
        try? modelContext.save()
        createdPattern = pattern
        navigateToCounter = true
    }
}
