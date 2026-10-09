import SwiftUI
import Combine

struct GridCellData: Codable {
    var row: Int
    var column: Int
    var colorHex: String
    var symbols: [String]
}

class GridEditorViewModel: ObservableObject {
    @Published var cells: [GridCell] = []
    @Published var scale: CGFloat = 1.0
    @Published var gridWidth: Int = 10
    @Published var gridHeight: Int = 10
    @Published var selectedColor: Color = .blue
    let cellSize: CGFloat = 40

    struct GridCell: Identifiable {
        let id = UUID()
        var row: Int
        var column: Int
        var color: Color
        var symbols: [String] = []
    }

    func drawGrid(context: GraphicsContext, size: CGSize) {
        let cols = gridWidth
        let rows = gridHeight
        for r in 0..<rows {
            for c in 0..<cols {
                let rect = CGRect(x: CGFloat(c) * cellSize * scale,
                                  y: CGFloat(r) * cellSize * scale,
                                  width: cellSize * scale,
                                  height: cellSize * scale)
                context.stroke(Path(rect), with: .color(.gray.opacity(0.3)), lineWidth: 1)
            }
        }
    }

    func drawCell(_ cell: GridCell, context: GraphicsContext) {
        let rect = CGRect(x: CGFloat(cell.column) * cellSize * scale,
                          y: CGFloat(cell.row) * cellSize * scale,
                          width: cellSize * scale,
                          height: cellSize * scale)
        context.fill(Path(rect), with: .color(cell.color.opacity(0.5)))
    }

    func handleDrag(_ value: DragGesture.Value) {
        let col = Int(value.location.x / (cellSize * scale))
        let row = Int(value.location.y / (cellSize * scale))
        guard col >= 0 && col < gridWidth && row >= 0 && row < gridHeight else { return }
        if !cells.contains(where: { $0.row == row && $0.column == col }) {
            cells.append(GridCell(row: row, column: col, color: selectedColor))
        }
    }

    func savePattern() -> Data? {
        let data = cells.map { cell -> GridCellData in
            let hex = Color.toHex(color: cell.color) ?? "#0000FF"
            return GridCellData(row: cell.row, column: cell.column, colorHex: hex, symbols: cell.symbols)
        }
        return try? JSONEncoder().encode(data)
    }

    func loadPattern(from data: Data) {
        guard let dataCells = try? JSONDecoder().decode([GridCellData].self, from: data) else { return }
        cells = dataCells.map {
            GridCell(row: $0.row,
                     column: $0.column,
                     color: Color(hex: $0.colorHex),
                     symbols: $0.symbols)
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    static func toHex(color: Color) -> String? {
        guard let components = UIColor(color).cgColor.components, components.count >= 3 else { return nil }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        return String(format: "#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
    }
}
