import SwiftUI

struct SmallMenuButton: View {
    let icon: String
    let title: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32))
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(Color("textColor"))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
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
