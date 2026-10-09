import SwiftUI

struct StatCardView: View {
    let value: String
    let title: String
    let icon: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(Color("textColor"))
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color("textColor"))
            Text(title)
                .font(.system(size: 13))
                .foregroundStyle(Color("textColor").opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15)
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
