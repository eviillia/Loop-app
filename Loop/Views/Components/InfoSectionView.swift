import SwiftUI

struct InfoSectionView: View {
    let title: String
    let icon: String
    let content: AnyView

    init<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = AnyView(content())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(Color("textColor"))
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color("textColor"))
                Spacer()
            }
            content
        }
        .padding(15)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color("backgroundColor").opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color("textColor").opacity(0.5), lineWidth: 1)
                )
        )
    }
}
