import SwiftUI
import SwiftData

struct GridEditorView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let pattern: Pattern
    let project: Project?

    @StateObject private var viewModel = GridEditorViewModel()
    @State private var canvasRect: CGRect = .zero
    @State private var initialScaleSet = false
    @State private var isDeleteMode = false

    var body: some View {
        ZStack {
            Color("backgroundColor").ignoresSafeArea()
            VStack(spacing: 0) {
                GeometryReader { geometry in
                    Canvas { context, size in
                        viewModel.drawGrid(context: context, size: size)
                        for cell in viewModel.cells {
                            viewModel.drawCell(cell, context: context)
                        }
                    }
                    .gesture(
                        isDeleteMode ?
                        nil :
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in viewModel.handleDrag(value) }
                    )
                    .gesture(
                        MagnificationGesture()
                            .onChanged { v in viewModel.scale = v }
                    )
                    .onTapGesture(count: 1, coordinateSpace: .local) { location in
                        guard isDeleteMode else { return }
                        let col = Int(location.x / (viewModel.cellSize * viewModel.scale))
                        let row = Int(location.y / (viewModel.cellSize * viewModel.scale))
                        if let index = viewModel.cells.firstIndex(where: { $0.row == row && $0.column == col }) {
                            viewModel.cells.remove(at: index)
                        }
                    }
                    .onAppear {
                        canvasRect = geometry.frame(in: .local)
                        viewModel.gridWidth = pattern.gridWidth ?? 20
                        viewModel.gridHeight = pattern.gridHeight ?? 30
                        if let data = pattern.graphicPatternData { viewModel.loadPattern(from: data) }
                        if !initialScaleSet {
                            let availableWidth = canvasRect.width - 40
                            let availableHeight = canvasRect.height - 40
                            let totalWidth = CGFloat(viewModel.gridWidth) * viewModel.cellSize
                            let totalHeight = CGFloat(viewModel.gridHeight) * viewModel.cellSize
                            let scaleX = availableWidth / totalWidth
                            let scaleY = availableHeight / totalHeight
                            let fitScale = min(scaleX, scaleY, 1.0)
                            viewModel.scale = max(0.3, min(fitScale, 1.0))
                            initialScaleSet = true
                        }
                    }
                }

                HStack {
                    Toggle("Удаление", isOn: $isDeleteMode)
                        .foregroundColor(Color("textColor"))
                    Spacer()
                    ColorPicker("", selection: $viewModel.selectedColor)
                        .labelsHidden()
                        .frame(width: 30)
                    Button("Сохранить") {
                        savePattern()
                        dismiss()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .padding()
            }
        }
        .navigationTitle(pattern.title)
    }

    private func savePattern() {
        if let data = viewModel.savePattern() {
            if let project = project, pattern.project == nil {
                project.patterns.append(pattern)
                pattern.project = project
            }
            if pattern.modelContext == nil {
                modelContext.insert(pattern)
            }
            pattern.user = authVM.currentUser
            pattern.gridWidth = viewModel.gridWidth
            pattern.gridHeight = viewModel.gridHeight
            pattern.graphicPatternData = data
            try? modelContext.save()
            FirebaseService.shared.savePrivatePattern(pattern)
        }
    }
}
