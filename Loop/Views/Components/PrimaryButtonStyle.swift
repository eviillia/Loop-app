import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .background(RoundedRectangle(cornerRadius: 15).fill(Color("textColor")))
            .foregroundColor(Color("backgroundColor"))
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}
