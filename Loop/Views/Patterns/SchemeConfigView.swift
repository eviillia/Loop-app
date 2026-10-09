import SwiftUI
import SwiftData

struct SchemeConfigView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let patternType: PatternType
    let project: Project?
    let onCreate: (String, Int, Int, String, [Yarn]) -> Void

    @State private var title = ""
    @State private var width = 5
    @State private var height = 5
    @State private var hookSize = ""
    @State private var selectedYarns: [Yarn] = []

    @Query(sort: \Yarn.name) private var allYarns: [Yarn]

    var filteredYarns: [Yarn] {
        guard let uid = authVM.currentUser?.firebaseID else { return [] }
        return allYarns.filter { $0.user?.firebaseID == uid }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color("backgroundColor").ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading) {
                            Text("Название схемы")
                                .foregroundColor(Color("textColor").opacity(0.7))
                            TextField("Введите название", text: $title)
                                .modifier(CalcTextFieldStyle())
                        }

                        if patternType == .circularEditor {
                            VStack(alignment: .leading) {
                                Text("Количество колец")
                                    .foregroundColor(Color("textColor").opacity(0.7))
                                TextField("5", value: $width, formatter: NumberFormatter())
                                    .keyboardType(.numberPad)
                                    .modifier(CalcTextFieldStyle())
                            }
                        } else if patternType == .gridEditor {
                            VStack(alignment: .leading) {
                                Text("Размер сетки")
                                    .foregroundColor(Color("textColor").opacity(0.7))
                                HStack {
                                    Text("Ширина:")
                                        .foregroundColor(Color("textColor"))
                                    TextField("5", value: $width, formatter: NumberFormatter())
                                        .keyboardType(.numberPad)
                                        .modifier(CalcTextFieldStyle())
                                }
                                HStack {
                                    Text("Высота:")
                                        .foregroundColor(Color("textColor"))
                                    TextField("5", value: $height, formatter: NumberFormatter())
                                        .keyboardType(.numberPad)
                                        .modifier(CalcTextFieldStyle())
                                }
                            }
                        }

                        VStack(alignment: .leading) {
                            Text("Размер инструмента (мм)")
                                .foregroundColor(Color("textColor").opacity(0.7))
                            TextField("Например, 3.5", text: $hookSize)
                                .keyboardType(.decimalPad)
                                .modifier(CalcTextFieldStyle())
                        }

                        VStack(alignment: .leading) {
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

                        HStack {
                            Image(systemName: "hand.pinch.fill")
                                .foregroundColor(Color("textColor"))
                            Text("Схему можно будет увеличивать и прокручивать")
                                .font(.caption)
                                .foregroundColor(Color("textColor").opacity(0.7))
                        }

                        Button("Создать") {
                            onCreate(title, width, height, hookSize, selectedYarns)
                            dismiss()
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(title.isEmpty)
                    }
                    .padding()
                }
            }
            .navigationTitle(patternType == .circularEditor ? "Круговая схема" : "Клетчатая схема")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
            }
        }
    }
}
