import SwiftUI
import SwiftData

struct CircularEditorView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let pattern: Pattern
    let project: Project?

    @StateObject private var viewModel = CircularEditorViewModel()
    @State private var initialScaleSet = false
    @State private var pinnedNoteText: String = ""
    @State private var editStitchMode = false

    var body: some View {
        ZStack {
            Color("backgroundColor").ignoresSafeArea()
            VStack(spacing: 0) {
                GeometryReader { geometry in
                    Canvas { context, size in
                        viewModel.drawGrid(context: context, size: size)
                        for element in viewModel.elements {
                            viewModel.drawElement(element, context: context, size: size)
                        }
                    }
                    .gesture(
                        editStitchMode ? nil :
                        DragGesture(minimumDistance: 0)
                            .onEnded { value in
                                if viewModel.isDeleteMode {
                                    viewModel.deleteElement(at: value.location, canvasSize: geometry.size)
                                } else {
                                    viewModel.handleDrop(value, canvasSize: geometry.size)
                                }
                            }
                    )
                    .gesture(
                        editStitchMode ? nil :
                        MagnificationGesture()
                            .onChanged { v in viewModel.scale = v }
                    )
                    .onTapGesture(count: 1) { location in
                        if viewModel.isDeleteMode {
                            viewModel.deleteElement(at: location, canvasSize: geometry.size)
                        } else if let elem = viewModel.findElement(at: location, canvasSize: geometry.size) {
                            viewModel.selectedElementID = elem.id
                        } else {
                            viewModel.selectedElementID = nil
                        }
                    }
                    .onAppear {
                        viewModel.canvasSize = geometry.size
                        if let rings = pattern.numberOfRings { viewModel.numberOfRings = rings }
                        if let data = pattern.graphicPatternData { viewModel.loadPattern(from: data) }
                        pinnedNoteText = pattern.pinnedNote ?? ""
                        if !initialScaleSet {
                            let availableWidth = geometry.size.width - 40
                            let availableHeight = geometry.size.height - 40
                            let maxRadius = (CGFloat(viewModel.numberOfRings) + 0.5) * CircularEditorViewModel.ringSpacing
                            let requiredWidth = maxRadius * 2
                            let scaleX = availableWidth / requiredWidth
                            let scaleY = availableHeight / requiredWidth
                            let fitScale = min(scaleX, scaleY, 1.0)
                            viewModel.scale = max(0.3, min(fitScale, 1.0))
                            initialScaleSet = true
                        }
                    }
                }
                .overlay(
                    Group {
                        if editStitchMode, viewModel.selectedElementID != nil {
                            Color.clear
                                .contentShape(Rectangle())
                                .gesture(
                                    MagnificationGesture()
                                        .onChanged { value in
                                            viewModel.updateSelectedElementScale(value)
                                        }
                                )
                                .simultaneousGesture(
                                    RotationGesture()
                                        .onChanged { angle in
                                            viewModel.updateSelectedElementRotation(angle.degrees)
                                        }
                                )
                                .simultaneousGesture(
                                    DragGesture(minimumDistance: 0)
                                        .onChanged { value in
                                            viewModel.moveSelectedElement(to: value.location, canvasSize: viewModel.canvasSize)
                                        }
                                )
                        }
                    }
                )

                VStack(spacing: 8) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(viewModel.availableStitches, id: \.self) { stitch in
                                Image(stitch)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 40, height: 40)
                                    .padding(4)
                                    .background(viewModel.currentStitchType == stitch ? Color.blue.opacity(0.3) : Color.clear)
                                    .cornerRadius(8)
                                    .onTapGesture {
                                        guard !editStitchMode else { return }
                                        viewModel.currentStitchType = stitch
                                    }
                            }
                        }
                    }

                    HStack {
                        Toggle("Значок", isOn: $editStitchMode)
                            .foregroundColor(Color("textColor"))
                            .onChange(of: editStitchMode) { newValue in
                                if newValue {
                                    viewModel.selectLastElement()
                                }
                            }
                        Toggle("Удаление", isOn: $viewModel.isDeleteMode)
                            .foregroundColor(Color("textColor"))
                        Spacer()
                    }
                    .padding(.horizontal)

                    TextField("Заметка к значкам (необязательно)", text: $pinnedNoteText)
                        .modifier(CalcTextFieldStyle())
                        .padding(.horizontal)

                    Button("Сохранить") {
                        savePattern()
                        dismiss()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .padding()
                .background(Color.gray.opacity(0.1))
            }
        }
        .navigationTitle(pattern.title)
    }

    private func savePattern() {
        if let data = viewModel.savePattern() {
            pattern.user = authVM.currentUser
            pattern.numberOfRings = viewModel.numberOfRings
            pattern.graphicPatternData = data
            pattern.pinnedNote = pinnedNoteText.isEmpty ? nil : pinnedNoteText
            try? modelContext.save()
            FirebaseService.shared.savePrivatePattern(pattern)
        }
    }
}
