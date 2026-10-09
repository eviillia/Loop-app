import SwiftUI
import FirebaseFirestore


struct PublicProjectCard: View {
    
    let project: PublicProject
    var onUserTap: (() -> Void)? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let userId = project.userId, !userId.isEmpty {
                Button {
                    onUserTap?()
                } label: {
                    Text("Автор: \(project.username)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }

            if let base64 = project.mainImageBase64,
               let data = Data(base64Encoded: base64),
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable().scaledToFill()
                    .frame(height: 150).clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 150)
                    .overlay(Image(systemName: "photo").font(.largeTitle).foregroundColor(.white))
            }

            Text(project.title).font(.headline).foregroundColor(Color("textColor"))
            HStack {
                Label(project.difficultyLevel, systemImage: "chart.bar")
                Spacer()
                Text(project.status)
                    .font(.caption).padding(.horizontal,8).padding(.vertical,4)
                    .background(Color.green.opacity(0.2)).cornerRadius(8)
            }
            .font(.caption).foregroundColor(Color("textColor").opacity(0.8))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color("backgroundColor").opacity(0.15))
                .overlay(RoundedRectangle(cornerRadius:15).stroke(Color("textColor").opacity(0.5), lineWidth:1))
        )
    }
}
