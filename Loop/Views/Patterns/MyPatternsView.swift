import SwiftUI
import SwiftData
import FirebaseAuth

struct MyPatternsView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Pattern.createdAt, order: .reverse) private var allPatterns: [Pattern]

    var patterns: [Pattern] {
        guard let currentUserID = authVM.currentUser?.firebaseID else { return [] }
        return allPatterns.filter { $0.user?.firebaseID == currentUserID }
    }

    var body: some View {
        ZStack {
            Color("backgroundColor").ignoresSafeArea()
            if patterns.isEmpty {
                Text("У вас пока нет сохранённых схем")
                    .foregroundStyle(Color("textColor"))
            } else {
                List {
                    ForEach(patterns) { pattern in
                        NavigationLink(destination: patternView(for: pattern)) {
                            PatternRowView(pattern: pattern)
                        }
                        .listRowBackground(Color.clear)
                    }
                    .onDelete(perform: deletePattern)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color("backgroundColor"))
            }
        }
        .navigationTitle("Мои схемы")
    }

    @ViewBuilder
    private func patternView(for pattern: Pattern) -> some View {
        switch pattern.type {
        case .circularEditor:
            CircularPatternView(pattern: pattern)
        case .gridEditor:
            GridPatternView(pattern: pattern)
        case .textEditor:
            TextPatternView(pattern: pattern)
        default:
            Text("Неизвестный тип")
        }
    }

    private func deletePattern(at offsets: IndexSet) {
        for index in offsets {
            let pattern = patterns[index]
            FirebaseService.shared.deletePrivatePattern(pattern)
            modelContext.delete(pattern)
        }
        try? modelContext.save()
    }
}
