import SwiftUI

struct PatternRowView: View {
    let pattern: Pattern

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(pattern.title).font(.headline)
                HStack {
                    Image(systemName: iconForType(pattern.type))
                    Text(pattern.type.rawValue)
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            Spacer()
            Text("Ряд: \(pattern.currentRow)")
                .font(.caption)
                .padding(5)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(5)
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.05)))
        .foregroundColor(Color("textColor"))
    }

    private func iconForType(_ type: PatternType) -> String {
        switch type {
        case .circularEditor: return "circle.circle"
        case .gridEditor: return "square.grid.3x3"
        case .textEditor: return "text.alignleft"
        case .uploaded: return "doc"
        }
    }
}
