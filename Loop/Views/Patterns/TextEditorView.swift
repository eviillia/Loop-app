import SwiftUI
import SwiftData

struct TextEditorView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let project: Project?

    @State private var title = ""
    @State private var hookSizeString = ""
    @State private var rows: [String] = [""]
    @State private var selectedYarns: [Yarn] = []
    @Query(sort: \Yarn.name) private var allYarns: [Yarn]

    var filteredYarns: [Yarn] {
        guard let uid = authVM.currentUser?.firebaseID else { return [] }
        return allYarns.filter { $0.user?.firebaseID == uid }
    }

    var body: some View {
        ZStack {
            Color("backgroundColor").ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Название схемы")
                            .foregroundColor(Color("textColor").opacity(0.7))
                        TextField("Введите название", text: $title)
                            .modifier(CalcTextFieldStyle())
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Размер крючка (мм)")
                            .foregroundColor(Color("textColor").opacity(0.7))
                        TextField("Например, 3.5", text: $hookSizeString)
                            .keyboardType(.decimalPad)
                            .modifier(CalcTextFieldStyle())
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Пряжа")
                            .foregroundColor(Color("textColor").opacity(0.7))
                        Menu {
                            ForEach(filteredYarns) { yarn in
                                Button {
                                    if let idx = selectedYarns.firstIndex(where: { $0.yarnID == yarn.yarnID }) {
                                        selectedYarns.remove(at: idx)
                                    } else {
                                        selectedYarns.append(yarn)
                                    }
                                } label: {
                                    HStack {
                                        Text(yarn.name)
                                        if selectedYarns.contains(where: { $0.yarnID == yarn.yarnID }) {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Text(selectedYarns.isEmpty ? "Выбрать пряжу" : selectedYarns.map { $0.name }.joined(separator: ", "))
                                    .foregroundColor(Color("textColor"))
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(Color("textColor"))
                            }
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 10)
                                .stroke(Color("textColor").opacity(0.5), lineWidth: 1))
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Схема (по рядам)")
                            .foregroundColor(Color("textColor").opacity(0.7))
                        ForEach(rows.indices, id: \.self) { index in
                            HStack(alignment: .top) {
                                Text("Ряд \(index + 1):")
                                    .frame(width: 50, alignment: .leading)
                                    .foregroundColor(Color("textColor").opacity(0.7))
                                TextField("Описание ряда", text: $rows[index])
                                    .modifier(CalcTextFieldStyle())
                                    .onSubmit {
                                        if index == rows.count - 1 && !rows[index].trimmingCharacters(in: .whitespaces).isEmpty {
                                            rows.append("")
                                        }
                                    }
                            }
                        }
                    }

                    Button(action: savePattern) {
                        Text("Сохранить схему")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 15).stroke(Color("textColor"), lineWidth: 1))
                    }
                    .foregroundColor(Color("textColor"))
                    .padding(.top, 10)
                }
                .padding()
            }
        }
        .navigationTitle("Текстовая схема")
    }

    private func savePattern() {
        while let last = rows.last, last.trimmingCharacters(in: .whitespaces).isEmpty {
            rows.removeLast()
        }
        let nonEmptyRows = rows.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard !nonEmptyRows.isEmpty else { return }

        let pattern = Pattern(title: title.isEmpty ? "Текстовая схема" : title, type: .textEditor)
        pattern.textPattern = nonEmptyRows.joined(separator: "\n")
        pattern.hookSize = Double(hookSizeString)
        pattern.yarns = selectedYarns
        pattern.user = authVM.currentUser
        if let project = project {
            project.patterns.append(pattern)
            pattern.project = project
        }
        modelContext.insert(pattern)
        try? modelContext.save()
        FirebaseService.shared.savePrivatePattern(pattern)
        dismiss()
    }
}
