import SwiftUI

struct TextPatternView: View {
    let pattern: Pattern

    var body: some View {
        ZStack {
            Color("backgroundColor").ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(pattern.title)
                            .font(.title2.bold())
                            .foregroundColor(Color("textColor"))
                        if let hook = pattern.hookSize {
                            Text("Крючок: \(String(format: "%.1f", hook)) мм")
                                .font(.subheadline)
                                .foregroundColor(Color("textColor"))
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
                                }
                            }
                        }
                    }
                    .foregroundColor(Color("textColor"))
                    .padding(.horizontal)
                    .padding(.bottom, 16)

                    if let text = pattern.textPattern {
                        let rows = text.components(separatedBy: "\n")
                        ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                            HStack(alignment: .top) {
                                Text("Ряд \(index + 1):")
                                    .bold()
                                    .frame(width: 60, alignment: .leading)
                                    .foregroundColor(Color("textColor"))
                                Text(row)
                                    .foregroundColor(Color("textColor"))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .font(.callout)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color("backgroundColor").opacity(0.5))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color("textColor").opacity(0.2), lineWidth: 1)
                                    )
                            )
                            .padding(.horizontal)
                            .padding(.top, 4)
                        }
                    }
                }
                .padding(.vertical)
            }
        }
        .navigationTitle(pattern.title)
    }
}
