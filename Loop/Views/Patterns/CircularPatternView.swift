import SwiftUI

struct CircularPatternView: View {
    let pattern: Pattern
    @StateObject private var viewModel = CircularEditorViewModel()

    @State private var canvasRect: CGRect = .zero
    @State private var initialScaleSet = false

    var body: some View {
        ZStack {
            Color("backgroundColor").ignoresSafeArea()
            VStack(spacing: 0) {
                VStack(spacing: 8) {
                    Text(pattern.title).font(.title2).bold()
                    if let hook = pattern.hookSize {
                        Text("Крючок: \(String(format: "%.1f", hook)) мм").font(.subheadline)
                    }
                    if let yarns = pattern.yarns, !yarns.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(yarns, id: \.yarnID) { yarn in
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(yarn.name).font(.caption).bold()
                                    Text("Цвет: \(yarn.color)").font(.caption2)
                                    if let brand = yarn.brand { Text("Бренд: \(brand)").font(.caption2) }
                                    if let material = yarn.material { Text("Состав: \(material)").font(.caption2) }
                                }
                                .padding(.vertical, 2)
                            }
                        }
                        .padding(.horizontal)
                    }
                    Text("Колец: \(viewModel.numberOfRings)").font(.caption)
                    if let note = pattern.pinnedNote, !note.isEmpty {
                        Text(note)
                            .font(.caption)
                            .foregroundColor(Color("textColor").opacity(0.8))
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.gray.opacity(0.15))
                            )
                            .padding(.horizontal)
                    }
                }
                .foregroundColor(Color("textColor"))
                .padding(.top)

                GeometryReader { geometry in
                    Canvas { context, size in
                        viewModel.drawGrid(context: context, size: size)
                        for element in viewModel.elements {
                            viewModel.drawElement(element, context: context, size: size)
                        }
                    }
                    .gesture(
                        MagnificationGesture()
                            .onChanged { v in viewModel.scale = v }
                    )
                    .onAppear {
                        canvasRect = geometry.frame(in: .local)
                        viewModel.canvasSize = canvasRect.size
                        if let rings = pattern.numberOfRings {
                            viewModel.numberOfRings = rings
                        }
                        if let data = pattern.graphicPatternData {
                            viewModel.loadPattern(from: data)
                        }
                        if !initialScaleSet {
                            let availableWidth = canvasRect.width - 40
                            let availableHeight = canvasRect.height - 40
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
            }
        }
    }
}
