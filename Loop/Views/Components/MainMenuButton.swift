import SwiftUI

struct MainMenuButton: View {
    let icon: String
    let title: String

    var body: some View {
        VStack {
            Image(systemName: icon)
                .font(.system(size: 50))
            Text(title)
                .font(.system(size: 20, weight: .bold))
        }
        .foregroundStyle(Color("textColor"))
        .frame(maxWidth: .infinity, minHeight: 80, maxHeight: 150)
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
