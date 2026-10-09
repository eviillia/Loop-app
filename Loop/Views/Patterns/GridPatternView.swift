import SwiftUI

struct GridPatternView: View {
    let pattern: Pattern
    @StateObject private var viewModel = GridEditorViewModel()

    @State private var canvasRect: CGRect = .zero
    @State private var initialScaleSet = false

    var body: some View {
        ZStack {
            Color("backgroundColor").ignoresSafeArea()
            VStack(spacing: 0) {
                VStack(spacing: 8) {
                    Text(pattern.title).font(.title2).bold()
                    if let hook = pattern.hookSize {
                        Text("Крючок: \(String(format: "%.1f", hook)) мм")
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
                    Text("Размер: \(viewModel.gridWidth) x \(viewModel.gridHeight)")
                        .font(.caption)
                }
                .foregroundColor(Color("textColor"))
                .padding(.top)

                GeometryReader { geometry in
                    Canvas { context, size in
                        viewModel.drawGrid(context: context, size: size)
                        for cell in viewModel.cells {
                            viewModel.drawCell(cell, context: context)
                        }
                    }
                    .gesture(
                        MagnificationGesture()
                            .onChanged { v in viewModel.scale = v }
                    )
                    .onAppear {
                        canvasRect = geometry.frame(in: .local)
                        viewModel.gridWidth = pattern.gridWidth ?? 20
                        viewModel.gridHeight = pattern.gridHeight ?? 30
                        if let data = pattern.graphicPatternData {
                            viewModel.loadPattern(from: data)
                        }
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
            }
        }
    }
}

