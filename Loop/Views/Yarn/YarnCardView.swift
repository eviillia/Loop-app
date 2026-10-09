import SwiftUI

struct YarnCardView: View {
    let yarn: Yarn

    var body: some View {
        VStack(spacing: 8) {
            if let data = yarn.imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 120)
                    .overlay(Image(systemName: "photo").foregroundColor(.white))
            }
            Text(yarn.name)
                .font(.headline)
                .foregroundColor(Color("textColor"))
            Text(yarn.color)
                .font(.caption)
                .foregroundColor(.secondary)
            if let brand = yarn.brand {
                Text(brand)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color("backgroundColor").opacity(0.15))
        )
    }
}
