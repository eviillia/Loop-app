import SwiftUI
import SwiftData

struct CreateSchemeView: View {
    let project: Project?
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.modelContext) private var modelContext

    @State private var showConfig = false
    @State private var selectedType: PatternType = .circularEditor

    @State private var openTextEditor = false
    @State private var navigateToEditor = false
    @State private var createdPattern: Pattern?
    @State private var editorType: PatternType?

    var body: some View {
        NavigationStack {
            ZStack {
                Color("backgroundColor").ignoresSafeArea()
                VStack(spacing: 30) {
                    Text("Выберите тип схемы")
                        .font(.title2)
                        .foregroundColor(Color("textColor"))

                    ForEach([PatternType.circularEditor, .gridEditor, .textEditor], id: \.self) { type in
                        Button {
                            selectedType = type
                            if type == .textEditor {
                                openTextEditor = true
                            } else {
                                showConfig = true
                            }
                        } label: {
                            HStack {
                                Image(systemName: iconFor(type))
                                Text(titleFor(type))
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color("backgroundColor").opacity(0.15))
                                    .overlay(RoundedRectangle(cornerRadius: 15)
                                        .stroke(Color("textColor").opacity(0.5), lineWidth: 1))
                            )
                            .foregroundColor(Color("textColor"))
                        }
                    }
                }
                .padding()

                NavigationLink(destination: TextEditorView(project: project), isActive: $openTextEditor) { EmptyView() }
                NavigationLink(destination: destinationEditor, isActive: $navigateToEditor) { EmptyView() }
            }
            .navigationTitle("Новая схема")
            .sheet(isPresented: $showConfig) {
                SchemeConfigView(patternType: selectedType, project: project) { title, width, height, hookSize, yarns in
                    let pattern = Pattern(title: title, type: selectedType)
                    pattern.user = project?.user ?? authVM.currentUser
                    pattern.hookSize = Double(hookSize)
                    pattern.yarns = yarns
                    if selectedType == .circularEditor {
                        pattern.numberOfRings = width
                    } else {
                        pattern.gridWidth = width
                        pattern.gridHeight = height
                    }
                    createdPattern = pattern
                    editorType = selectedType
                    navigateToEditor = true
                }
            }
        }
    }

    @ViewBuilder
    private var destinationEditor: some View {
        if let pattern = createdPattern, let type = editorType {
            switch type {
            case .circularEditor:
                CircularEditorView(pattern: pattern, project: project)
            case .gridEditor:
                GridEditorView(pattern: pattern, project: project)
            default:
                EmptyView()
            }
        }
    }

    private func iconFor(_ type: PatternType) -> String {
        switch type {
        case .circularEditor: return "circle.circle"
        case .gridEditor: return "square.grid.3x3"
        case .textEditor: return "text.alignleft"
        default: return "doc"
        }
    }

    private func titleFor(_ type: PatternType) -> String {
        switch type {
        case .circularEditor: return "Круговая сетка"
        case .gridEditor: return "Клетчатая сетка"
        case .textEditor: return "Текстовый редактор"
        default: return ""
        }
    }
}
