import SwiftUI
import SwiftData
import FirebaseAuth

struct SelectPatternView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Pattern.title) private var allPatterns: [Pattern]

    var patterns: [Pattern] {
        guard let uid = authVM.currentUser?.firebaseID else { return [] }
        return allPatterns.filter { $0.user?.firebaseID == uid }
    }

    var onSelect: (Pattern) -> Void

    var body: some View {
        NavigationStack {
            List(patterns) { pattern in
                Button { onSelect(pattern) } label: {
                    VStack(alignment: .leading) {
                        Text(pattern.title).font(.headline)
                        Text(pattern.type.rawValue).font(.caption).foregroundColor(.secondary)
                    }
                }
                .foregroundColor(Color("textColor"))
            }
            .navigationTitle("Выбрать схему")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Отмена") { dismiss() } } }
        }
    }
}

